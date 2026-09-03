public struct AgentModelInvocationContext: Sendable {
    public let toolCallResolver: (any AgentToolCallResolver)?

    public init(
        toolCallResolver: (any AgentToolCallResolver)? = nil
    ) {
        self.toolCallResolver = toolCallResolver
    }

    public static let `default` = Self()
}
