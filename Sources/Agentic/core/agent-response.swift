public struct AgentResponse: Sendable, Codable, Hashable {
    public let message: AgentMessage
    public let stopReason: AgentStopReason
    public let usage: AgentUsage?
    public let metadata: [String: String]

    public init(
        message: AgentMessage,
        stopReason: AgentStopReason,
        usage: AgentUsage? = nil,
        metadata: [String: String] = [:]
    ) {
        self.message = message
        self.stopReason = stopReason
        self.usage = usage
        self.metadata = metadata
    }
}
