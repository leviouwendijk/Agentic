import Foundation
import Primitives

extension ToolLoopExecutor {
    func requestWithCurrentState(
        from request: AgentRequest,
        messages: [AgentMessage]
    ) -> AgentRequest {
        AgentRequest(
            model: request.model,
            messages: messages,
            tools: toolDefinitions(
                fallback: request.tools
            ),
            generationConfiguration: request.generationConfiguration,
            metadata: request.metadata
        )
    }

    func toolDefinitions(
        fallback: [AgentToolDefinition]
    ) -> [AgentToolDefinition] {
        let definitions = toolRegistry.definitions

        guard !definitions.isEmpty else {
            return fallback
        }

        return definitions
    }

    func toolCalls(
        in message: AgentMessage
    ) -> [AgentToolCall] {
        message.content.blocks.compactMap { block in
            guard case .tool_call(let value) = block else {
                return nil
            }

            return value
        }
    }

    func appendToolResultBlock(
        _ block: AgentContentBlock,
        to state: inout AgentLoopState
    ) {
        if configuration.appendToolResultsAsMessages {
            state.messages.append(
                AgentMessage(
                    role: .tool,
                    content: .init(
                        blocks: [block]
                    )
                )
            )
            return
        }

        if let last = state.messages.last,
           last.role == .tool {
            var updated = last
            updated.content.blocks.append(
                block
            )
            state.messages.removeLast()
            state.messages.append(
                updated
            )
            return
        }

        state.messages.append(
            AgentMessage(
                role: .tool,
                content: .init(
                    blocks: [block]
                )
            )
        )
    }

    func resolveApprovalDecision(
        for preflight: ToolPreflight,
        requirement: ApprovalRequirement
    ) async throws -> ApprovalDecision {
        guard let approvalHandler else {
            return requirement.decision
        }

        return try await approvalHandler.decide(
            on: preflight,
            requirement: requirement
        )
    }

    func executeApprovedToolCall(
        _ toolCall: AgentToolCall
    ) async -> AgentToolResult {
        do {
            return try await toolRegistry.call(
                toolCall,
                workspace: workspace
            )
        } catch {
            return makeToolErrorResult(
                for: toolCall,
                error: error
            )
        }
    }

    func makeDeniedToolResult(
        for toolCall: AgentToolCall,
        preflight: ToolPreflight,
        requirement: ApprovalRequirement
    ) -> AgentToolResult {
        let payload = ToolDenialPayload(
            kind: "tool_denied",
            toolCallID: toolCall.id,
            toolName: toolCall.name,
            requirement: requirement.rawValue,
            summary: preflight.summary
        )

        return AgentToolResult(
            toolCallID: toolCall.id,
            name: toolCall.name,
            output: try! JSONToolBridge.encode(payload),
            isError: true
        )
    }

    func makeToolErrorResult(
        for toolCall: AgentToolCall,
        error: Error
    ) -> AgentToolResult {
        let payload = ToolErrorPayload(
            kind: "tool_error",
            toolCallID: toolCall.id,
            toolName: toolCall.name,
            message: localizedDescription(for: error)
        )

        return AgentToolResult(
            toolCallID: toolCall.id,
            name: toolCall.name,
            output: try! JSONToolBridge.encode(payload),
            isError: true
        )
    }

    func localizedDescription(
        for error: Error
    ) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription,
           !description.isEmpty {
            return description
        }

        return String(
            describing: error
        )
    }

    func compactIfNeeded(
        _ checkpoint: inout AgentHistoryCheckpoint
    ) async throws {
        guard let strategy = configuration.compactionStrategy else {
            return
        }

        guard checkpoint.phase == .ready_for_model else {
            return
        }

        let compactor = AgentCompactor(
            strategy: strategy
        )

        guard let compacted = compactor.compact(
            checkpoint: &checkpoint
        ) else {
            return
        }

        checkpoint.events.append(
            .init(
                kind: .compaction,
                iteration: checkpoint.state.iteration,
                messageID: compacted.summaryMessageID,
                summary: "compacted \(compacted.replacedMessageCount) earlier message(s)"
            )
        )

        try await saveCheckpoint(
            &checkpoint
        )
    }

    func saveCheckpoint(
        _ checkpoint: inout AgentHistoryCheckpoint
    ) async throws {
        guard configuration.persistsHistory else {
            return
        }

        guard let historyStore else {
            return
        }

        checkpoint.touch()

        try await historyStore.saveCheckpoint(
            checkpoint
        )
    }
}
