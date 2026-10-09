/// An invocation-specific request and typed decoder. A Decision query may capture
/// bindings here without any mutable adapter-wide state.
public struct PreparedInference<Output: Sendable>: Sendable {
    public var adaptation: InferenceAdaptation
    private let decodeResponse: @Sendable (AgentResponse) throws -> Output

    public init(
        adaptation: InferenceAdaptation,
        decode: @escaping @Sendable (AgentResponse) throws -> Output
    ) {
        self.adaptation = adaptation
        self.decodeResponse = decode
    }

    public func decode(_ response: AgentResponse) throws -> Output {
        try decodeResponse(response)
    }
}
