public enum AgentStreamEvent: Sendable, Codable, Hashable {
    case messagedelta(MessageContentBlock)
    case toolcall(FunctionCall)
    case toolresult(ToolExecution.Response)
    case completed(AgentResponse)
}
