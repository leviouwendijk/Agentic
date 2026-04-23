public enum AgentStreamEvent: Sendable, Codable, Hashable {
    case messagedelta(AgentContentBlock)
    case toolcall(AgentToolCall)
    case toolresult(AgentToolResult)
    case completed(AgentResponse)
}
