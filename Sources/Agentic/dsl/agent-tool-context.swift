public struct AgentToolContext: Sendable {
    public let workspace: AgentWorkspace?
    public let sessionID: String?
    public let metadata: [String: String]

    public init(
        workspace: AgentWorkspace? = nil,
        sessionID: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.workspace = workspace
        self.sessionID = sessionID
        self.metadata = metadata
    }
}
