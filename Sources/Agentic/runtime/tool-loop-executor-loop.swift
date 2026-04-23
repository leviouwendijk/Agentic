import Foundation

extension ToolLoopExecutor {
    func runLoop(
        from initialCheckpoint: AgentHistoryCheckpoint
    ) async throws -> AgentRunResult {
        var checkpoint = initialCheckpoint

        while true {
            guard checkpoint.state.iteration < configuration.maximumIterations else {
                throw AgentRunLoopError.maximumIterationsExceeded(
                    configuration.maximumIterations
                )
            }

            switch checkpoint.phase {
            case .ready_for_model:
                checkpoint = try await performModelTurn(
                    from: checkpoint
                )

                if checkpoint.phase == .completed {
                    guard let response = checkpoint.lastResponse else {
                        throw AgentHistoryError.corruptedCheckpoint(
                            "completed checkpoint without final response"
                        )
                    }

                    return .completed(
                        sessionID: checkpoint.id,
                        response: response,
                        state: checkpoint.state,
                        events: checkpoint.events
                    )
                }

            case .processing_tool_calls:
                let processed = try await processToolCalls(
                    from: checkpoint
                )

                switch processed {
                case .continueLoop(let updatedCheckpoint):
                    checkpoint = updatedCheckpoint

                case .result(let result):
                    return result
                }

            case .awaiting_approval:
                guard let response = checkpoint.lastResponse else {
                    throw AgentHistoryError.corruptedCheckpoint(
                        "awaiting approval without last response"
                    )
                }

                guard let pendingApproval = checkpoint.pendingApproval else {
                    throw AgentHistoryError.corruptedCheckpoint(
                        "awaiting approval without pending approval payload"
                    )
                }

                return .awaitingApproval(
                    sessionID: checkpoint.id,
                    response: response,
                    pendingApproval: pendingApproval,
                    state: checkpoint.state,
                    events: checkpoint.events
                )

            case .completed:
                guard let response = checkpoint.lastResponse else {
                    throw AgentHistoryError.corruptedCheckpoint(
                        "completed checkpoint without final response"
                    )
                }

                return .completed(
                    sessionID: checkpoint.id,
                    response: response,
                    state: checkpoint.state,
                    events: checkpoint.events
                )
            }
        }
    }

    func performModelTurn(
        from checkpoint: AgentHistoryCheckpoint
    ) async throws -> AgentHistoryCheckpoint {
        var checkpoint = checkpoint

        try await compactIfNeeded(
            &checkpoint
        )

        var preparedRequest = requestWithCurrentState(
            from: checkpoint.originalRequest,
            messages: checkpoint.state.messages
        )

        for harnessExtension in extensions {
            preparedRequest = try await harnessExtension.prepare(
                request: preparedRequest,
                state: checkpoint.state
            )
        }

        let response = try await adapter.complete(
            request: preparedRequest
        )

        checkpoint.state.iteration += 1
        checkpoint.state.messages.append(
            response.message
        )
        checkpoint.lastResponse = response
        checkpoint.pendingApproval = nil

        checkpoint.events.append(
            .init(
                kind: .assistant_response,
                iteration: checkpoint.state.iteration,
                messageID: response.message.id,
                summary: response.stopReason.rawValue
            )
        )

        for harnessExtension in extensions {
            try await harnessExtension.didReceive(
                response: response,
                state: checkpoint.state
            )
        }

        let toolCalls = toolCalls(
            in: response.message
        )

        if response.stopReason == .tool_use,
           !toolCalls.isEmpty {
            checkpoint.phase = .processing_tool_calls
        } else {
            checkpoint.phase = .completed
        }

        try await saveCheckpoint(
            &checkpoint
        )

        return checkpoint
    }

    func processToolCalls(
        from checkpoint: AgentHistoryCheckpoint
    ) async throws -> ToolProcessingOutcome {
        var checkpoint = checkpoint

        guard let response = checkpoint.lastResponse else {
            throw AgentHistoryError.corruptedCheckpoint(
                "processing tool calls without last response"
            )
        }

        let calls = toolCalls(
            in: response.message
        )

        guard !calls.isEmpty else {
            checkpoint.phase = .ready_for_model
            checkpoint.lastResponse = nil
            checkpoint.pendingApproval = nil

            try await saveCheckpoint(
                &checkpoint
            )

            return .continueLoop(checkpoint)
        }

        for toolCall in calls {
            let preflight: ToolPreflight

            do {
                preflight = try await toolRegistry.preflight(
                    toolCall,
                    workspace: workspace
                )
            } catch {
                let result = makeToolErrorResult(
                    for: toolCall,
                    error: error
                )

                appendToolResultBlock(
                    .tool_result(result),
                    to: &checkpoint.state
                )

                checkpoint.events.append(
                    .init(
                        kind: .tool_error,
                        iteration: checkpoint.state.iteration,
                        toolCallID: toolCall.id,
                        toolName: toolCall.name,
                        summary: localizedDescription(for: error)
                    )
                )

                try await saveCheckpoint(
                    &checkpoint
                )

                continue
            }

            checkpoint.events.append(
                .init(
                    kind: .tool_preflight,
                    iteration: checkpoint.state.iteration,
                    toolCallID: toolCall.id,
                    toolName: toolCall.name,
                    summary: preflight.summary
                )
            )

            let requirement = configuration.toolExecutionPolicy.evaluate(
                preflight
            )

            switch requirement {
            case .no_approval_needed:
                let result = await executeApprovedToolCall(
                    toolCall
                )

                appendToolResultBlock(
                    .tool_result(result),
                    to: &checkpoint.state
                )

                checkpoint.events.append(
                    .init(
                        kind: result.isError ? .tool_error : .tool_result,
                        iteration: checkpoint.state.iteration,
                        toolCallID: toolCall.id,
                        toolName: toolCall.name,
                        summary: result.isError
                            ? "tool execution failed"
                            : "tool executed"
                    )
                )

                try await saveCheckpoint(
                    &checkpoint
                )

            case .denied_forbidden:
                let result = makeDeniedToolResult(
                    for: toolCall,
                    preflight: preflight,
                    requirement: requirement
                )

                appendToolResultBlock(
                    .tool_result(result),
                    to: &checkpoint.state
                )

                checkpoint.events.append(
                    .init(
                        kind: .tool_denied,
                        iteration: checkpoint.state.iteration,
                        toolCallID: toolCall.id,
                        toolName: toolCall.name,
                        summary: "denied by execution policy"
                    )
                )

                try await saveCheckpoint(
                    &checkpoint
                )

            case .needs_human_review:
                let decision = try await resolveApprovalDecision(
                    for: preflight,
                    requirement: requirement
                )

                switch decision {
                case .approved:
                    checkpoint.events.append(
                        .init(
                            kind: .tool_approved,
                            iteration: checkpoint.state.iteration,
                            toolCallID: toolCall.id,
                            toolName: toolCall.name,
                            summary: "approved"
                        )
                    )

                    let result = await executeApprovedToolCall(
                        toolCall
                    )

                    appendToolResultBlock(
                        .tool_result(result),
                        to: &checkpoint.state
                    )

                    checkpoint.events.append(
                        .init(
                            kind: result.isError ? .tool_error : .tool_result,
                            iteration: checkpoint.state.iteration,
                            toolCallID: toolCall.id,
                            toolName: toolCall.name,
                            summary: result.isError
                                ? "tool execution failed"
                                : "tool executed"
                        )
                    )

                    try await saveCheckpoint(
                        &checkpoint
                    )

                case .denied:
                    let result = makeDeniedToolResult(
                        for: toolCall,
                        preflight: preflight,
                        requirement: requirement
                    )

                    appendToolResultBlock(
                        .tool_result(result),
                        to: &checkpoint.state
                    )

                    checkpoint.events.append(
                        .init(
                            kind: .tool_denied,
                            iteration: checkpoint.state.iteration,
                            toolCallID: toolCall.id,
                            toolName: toolCall.name,
                            summary: "denied after review"
                        )
                    )

                    try await saveCheckpoint(
                        &checkpoint
                    )

                case .needshuman:
                    let pendingApproval = PendingApproval(
                        toolCall: toolCall,
                        preflight: preflight,
                        requirement: requirement
                    )

                    checkpoint.pendingApproval = pendingApproval
                    checkpoint.phase = .awaiting_approval

                    checkpoint.events.append(
                        .init(
                            kind: .pending_approval,
                            iteration: checkpoint.state.iteration,
                            toolCallID: toolCall.id,
                            toolName: toolCall.name,
                            summary: preflight.summary
                        )
                    )

                    try await saveCheckpoint(
                        &checkpoint
                    )

                    guard let response = checkpoint.lastResponse else {
                        throw AgentHistoryError.corruptedCheckpoint(
                            "awaiting approval without last response"
                        )
                    }

                    return .result(
                        .awaitingApproval(
                            sessionID: checkpoint.id,
                            response: response,
                            pendingApproval: pendingApproval,
                            state: checkpoint.state,
                            events: checkpoint.events
                        )
                    )
                }
            }
        }

        checkpoint.phase = .ready_for_model
        checkpoint.lastResponse = nil
        checkpoint.pendingApproval = nil

        try await saveCheckpoint(
            &checkpoint
        )

        return .continueLoop(checkpoint)
    }
}
