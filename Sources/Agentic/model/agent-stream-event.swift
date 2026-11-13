public enum AgentStreamEvent: Sendable, Codable, Hashable {
    case messagedelta(MessageContentBlock)
    case call(FunctionCall)
    case result(FunctionCall.Response)
    case completed(AgentResponse)
}
