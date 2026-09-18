public enum AgentStreamEvent: Sendable, Codable, Hashable {
    case messagedelta(AgentContentBlock)
    case toolcall(ToolCall)
    case toolresult(ToolResult)
    case completed(AgentResponse)
}
