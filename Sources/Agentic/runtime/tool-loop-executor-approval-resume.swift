public extension ToolLoopExecutor {
    func resume(
        _ checkpoint: AgentHistoryCheckpoint,
        approvalDecision: ApprovalDecision,
        metadata: [String: String] = [:]
    ) async throws -> AgentRunResult {
        var checkpoint = checkpoint

        guard let pendingApproval = checkpoint.resolvedSuspension?.pendingApproval else {
            throw AgentHistoryError.corruptedCheckpoint(
                "checkpoint is not awaiting approval"
            )
        }

        switch approvalDecision {
        case .approved:
            try await appendRunEvent(
                .init(
                    kind: .tool_approved,
                    iteration: checkpoint.state.iteration,
                    toolCallID: pendingApproval.toolCall.id,
                    toolName: pendingApproval.toolCall.name,
                    summary: metadata["summary"] ?? "approved after suspended review"
                ),
                to: &checkpoint
            )

            let result = await executeApprovedToolCall(
                pendingApproval.toolCall
            )

            appendToolResultBlock(
                .tool_result(result),
                to: &checkpoint.state
            )

            try await recordToolResult(
                result
            )

            try await appendRunEvent(
                .init(
                    kind: result.isError ? .tool_error : .tool_result,
                    iteration: checkpoint.state.iteration,
                    toolCallID: pendingApproval.toolCall.id,
                    toolName: pendingApproval.toolCall.name,
                    summary: result.isError
                        ? "tool execution failed after suspended approval"
                        : "tool executed after suspended approval"
                ),
                to: &checkpoint
            )

            checkpoint.clearSuspension()
            checkpoint.phase = .ready_for_model
            checkpoint.lastResponse = nil

            try await saveCheckpoint(
                &checkpoint
            )

            return try await runLoop(
                from: checkpoint
            )

        case .denied:
            let result = makeDeniedToolResult(
                for: pendingApproval.toolCall,
                preflight: pendingApproval.preflight,
                requirement: pendingApproval.requirement
            )

            appendToolResultBlock(
                .tool_result(result),
                to: &checkpoint.state
            )

            try await recordToolResult(
                result
            )

            try await appendRunEvent(
                .init(
                    kind: .tool_denied,
                    iteration: checkpoint.state.iteration,
                    toolCallID: pendingApproval.toolCall.id,
                    toolName: pendingApproval.toolCall.name,
                    summary: metadata["summary"] ?? "denied after suspended review"
                ),
                to: &checkpoint
            )

            checkpoint.clearSuspension()
            checkpoint.phase = .ready_for_model
            checkpoint.lastResponse = nil

            try await saveCheckpoint(
                &checkpoint
            )

            return try await runLoop(
                from: checkpoint
            )

        case .needshuman:
            return try suspendedResult(
                from: checkpoint
            )
        }
    }
}
