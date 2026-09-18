public struct AgentModelInvocationContext: Sendable {
    public let toolCallResolver: (any ToolCallResolver)?

    public init(
        toolCallResolver: (any ToolCallResolver)? = nil
    ) {
        self.toolCallResolver = toolCallResolver
    }

    public static let `default` = Self()
}
