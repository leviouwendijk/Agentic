import Foundation

public actor AgentRunner {
    public let adapter: any AgentModelAdapter
    public let configuration: AgentRunnerConfiguration
    public let toolRegistry: ToolRegistry
    public let extensions: [any AgentHarnessExtension]
    public let workspace: AgentWorkspace?
    public let approvalHandler: (any ToolApprovalHandler)?
    public let historyStore: (any AgentHistoryStore)?

    public init(
        adapter: any AgentModelAdapter,
        configuration: AgentRunnerConfiguration = .default,
        toolRegistry: ToolRegistry = .init(),
        extensions: [any AgentHarnessExtension] = [],
        workspace: AgentWorkspace? = nil,
        approvalHandler: (any ToolApprovalHandler)? = nil,
        historyStore: (any AgentHistoryStore)? = nil
    ) {
        self.adapter = adapter
        self.configuration = configuration
        self.toolRegistry = toolRegistry
        self.extensions = extensions
        self.workspace = workspace
        self.approvalHandler = approvalHandler
        self.historyStore = historyStore
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
            historyStore: historyStore
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

        case .ready_for_model, .processing_tool_calls:
            return try await ToolLoopExecutor(
                adapter: adapter,
                configuration: configuration,
                toolRegistry: toolRegistry,
                extensions: extensions,
                workspace: workspace,
                approvalHandler: approvalHandler,
                historyStore: historyStore
            ).resume(checkpoint)
        }
    }
}
