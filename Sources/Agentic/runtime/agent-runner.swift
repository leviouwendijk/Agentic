import Foundation

public actor AgentRunner {
    public let adapter: any AgentModelAdapter
    public let configuration: AgentRunnerConfiguration
    public let toolRegistry: ToolRegistry
    public let extensions: [any AgentHarnessExtension]
    public let workspace: AgentWorkspace?
    public let approvalHandler: (any ToolApprovalHandler)?
    public let historyStore: (any AgentHistoryStore)?
    public let eventSinks: [any AgentRunEventSink]
    public let costTracker: AgentCostTracker?

    public init(
        adapter: any AgentModelAdapter,
        configuration: AgentRunnerConfiguration = .default,
        toolRegistry: ToolRegistry = .init(),
        extensions: [any AgentHarnessExtension] = [],
        workspace: AgentWorkspace? = nil,
        approvalHandler: (any ToolApprovalHandler)? = nil,
        historyStore: (any AgentHistoryStore)? = nil,
        eventSinks: [any AgentRunEventSink] = [],
        costTracker: AgentCostTracker? = nil
    ) {
        self.adapter = adapter
        self.configuration = configuration
        self.toolRegistry = toolRegistry
        self.extensions = extensions
        self.workspace = workspace
        self.approvalHandler = approvalHandler
        self.historyStore = historyStore
        self.eventSinks = eventSinks
        self.costTracker = costTracker
    }

    public func run(
        _ request: AgentRequest,
        sessionID: String = UUID().uuidString
    ) async throws -> AgentRunResult {
        try await ToolLoopExecutor(
            adapter: adapter,
            configuration: configuration,
            toolRegistry: toolRegistry,
            extensions: extensions,
            workspace: workspace,
            approvalHandler: approvalHandler,
            historyStore: historyStore,
            eventSinks: eventSinks,
            costTracker: costTracker
        ).run(
            request,
            sessionID: sessionID
        )
    }

    public func resume(
        sessionID: String
    ) async throws -> AgentRunResult {
        guard let historyStore else {
            throw AgentHistoryError.historyStoreRequired
        }

        guard let checkpoint = try await historyStore.loadCheckpoint(
            sessionID: sessionID
        ) else {
            throw AgentHistoryError.checkpointNotFound(
                sessionID
            )
        }

        switch checkpoint.phase {
        case .suspended,
             .awaiting_approval:
            return try suspendedResult(
                from: checkpoint
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
                events: checkpoint.events,
                costRecord: checkpoint.costRecord
            )

        case .ready_for_model,
             .processing_tool_calls:
            return try await ToolLoopExecutor(
                adapter: adapter,
                configuration: configuration,
                toolRegistry: toolRegistry,
                extensions: extensions,
                workspace: workspace,
                approvalHandler: approvalHandler,
                historyStore: historyStore,
                eventSinks: eventSinks,
                costTracker: costTracker
            ).resume(checkpoint)
        }
    }

    public func resume(
        sessionID: String,
        userInput: String,
        metadata: [String: String] = [:]
    ) async throws -> AgentRunResult {
        try await resume(
            sessionID: sessionID,
            answer: .text(
                userInput
            ),
            metadata: metadata
        )
    }

    public func resume(
        sessionID: String,
        answer: UserInputAnswer,
        metadata: [String: String] = [:]
    ) async throws -> AgentRunResult {
        guard let historyStore else {
            throw AgentHistoryError.historyStoreRequired
        }

        guard let checkpoint = try await historyStore.loadCheckpoint(
            sessionID: sessionID
        ) else {
            throw AgentHistoryError.checkpointNotFound(
                sessionID
            )
        }

        return try await ToolLoopExecutor(
            adapter: adapter,
            configuration: configuration,
            toolRegistry: toolRegistry,
            extensions: extensions,
            workspace: workspace,
            approvalHandler: approvalHandler,
            historyStore: historyStore,
            eventSinks: eventSinks,
            costTracker: costTracker
        ).resume(
            checkpoint,
            answer: answer,
            metadata: metadata
        )
    }
}

private extension AgentRunner {
    func suspendedResult(
        from checkpoint: AgentHistoryCheckpoint
    ) throws -> AgentRunResult {
        guard let response = checkpoint.lastResponse else {
            throw AgentHistoryError.corruptedCheckpoint(
                "suspended checkpoint without last response"
            )
        }

        guard let suspension = checkpoint.resolvedSuspension else {
            throw AgentHistoryError.corruptedCheckpoint(
                "suspended checkpoint without suspension payload"
            )
        }

        switch suspension.reason {
        case .approval(let pendingApproval):
            return .awaitingApproval(
                sessionID: checkpoint.id,
                response: response,
                pendingApproval: pendingApproval,
                state: checkpoint.state,
                events: checkpoint.events,
                costRecord: checkpoint.costRecord
            )

        case .user_input(let pendingUserInput):
            return .awaitingUserInput(
                sessionID: checkpoint.id,
                response: response,
                pendingUserInput: pendingUserInput,
                state: checkpoint.state,
                events: checkpoint.events,
                costRecord: checkpoint.costRecord
            )
        }
    }
}
