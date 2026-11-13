public enum AgentStreamEvent: Sendable, Codable, Hashable {
    case messagedelta(MessageContentBlock)
    case call(FunctionCall)
    case result(ToolExecution.Response)
    case completed(AgentResponse)
}
