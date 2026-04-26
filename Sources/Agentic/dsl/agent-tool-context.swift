public enum AgentToolExecutionMode: String, Sendable, Codable, Hashable, CaseIterable {
    case model_tool_call
    case prepared_intent_replay
    case host_call
}

public struct AgentToolExecutionContext: Sendable {
    public let workspace: AgentWorkspace?
    public let sessionID: String?
    public let toolCallID: String?
    public let preparedIntentID: PreparedIntentIdentifier?
    public let executionMode: AgentToolExecutionMode
    public let metadata: [String: String]

    public init(
        workspace: AgentWorkspace? = nil,
        sessionID: String? = nil,
        toolCallID: String? = nil,
        preparedIntentID: PreparedIntentIdentifier? = nil,
        executionMode: AgentToolExecutionMode = .host_call,
        metadata: [String: String] = [:]
    ) {
        self.workspace = workspace
        self.sessionID = sessionID
        self.toolCallID = toolCallID
        self.preparedIntentID = preparedIntentID
        self.executionMode = executionMode
        self.metadata = metadata
    }

    public func withToolCallID(
        _ toolCallID: String?
    ) -> Self {
        .init(
            workspace: workspace,
            sessionID: sessionID,
            toolCallID: toolCallID,
            preparedIntentID: preparedIntentID,
            executionMode: executionMode,
            metadata: metadata
        )
    }

    public func withPreparedIntentID(
        _ preparedIntentID: PreparedIntentIdentifier?
    ) -> Self {
        .init(
            workspace: workspace,
            sessionID: sessionID,
            toolCallID: toolCallID,
            preparedIntentID: preparedIntentID,
            executionMode: executionMode,
            metadata: metadata
        )
    }

    public func withExecutionMode(
        _ executionMode: AgentToolExecutionMode
    ) -> Self {
        .init(
            workspace: workspace,
            sessionID: sessionID,
            toolCallID: toolCallID,
            preparedIntentID: preparedIntentID,
            executionMode: executionMode,
            metadata: metadata
        )
    }

    public func mergingMetadata(
        _ additionalMetadata: [String: String]
    ) -> Self {
        .init(
            workspace: workspace,
            sessionID: sessionID,
            toolCallID: toolCallID,
            preparedIntentID: preparedIntentID,
            executionMode: executionMode,
            metadata: metadata.merging(
                additionalMetadata
            ) { _, new in
                new
            }
        )
    }
}

public typealias AgentToolContext = AgentToolExecutionContext

// public struct AgentToolContext: Sendable {
//     public let workspace: AgentWorkspace?
//     public let sessionID: String?
//     public let metadata: [String: String]

//     public init(
//         workspace: AgentWorkspace? = nil,
//         sessionID: String? = nil,
//         metadata: [String: String] = [:]
//     ) {
//         self.workspace = workspace
//         self.sessionID = sessionID
//         self.metadata = metadata
//     }
// }
