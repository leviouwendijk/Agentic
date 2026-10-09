public enum AgentStreamEvent: Sendable, Codable, Hashable {
    case messagedelta(MessageContentBlock)
    case toolcall(ToolCall)
    case toolresult(ToolCall.Response)
    case completed(AgentResponse)
}
