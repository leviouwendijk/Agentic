public enum AgentStreamEvent: Sendable, Codable, Hashable {
    case messagedelta(MessageContentBlock)
    case toolcall(ToolCall)
    case toolresult(ToolResult)
    case completed(AgentResponse)
}
