public struct AgentModelInvocationContext: Sendable {
    public let functionCallResolver: (any FunctionCallResolver)?

    public init(
        functionCallResolver: (any FunctionCallResolver)? = nil
    ) {
        self.functionCallResolver = functionCallResolver
    }

    public static let `default` = Self()
}
