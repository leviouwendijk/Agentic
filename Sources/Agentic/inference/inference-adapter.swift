
public protocol InferenceAdapter: Sendable {
    var identifier: InferenceAdapterIdentifier { get }

    func prepare<InferenceType: Inference>(
        _ inference: InferenceType.Type,
        input: InferenceType.Input,
        realization: InferenceRealizationConfiguration
    ) throws -> InferenceAdaptation

    func decode<InferenceType: Inference>(
        _ inference: InferenceType.Type,
        response: AgentResponse
    ) throws -> InferenceType.Output

    func prepareInvocation<InferenceType: Inference>(
        _ inference: InferenceType.Type,
        input: InferenceType.Input,
        realization: InferenceRealizationConfiguration
    ) throws -> PreparedInference<InferenceType.Output>
}

public extension InferenceAdapter {
    /// Compatibility bridge for existing generic adapters and repair classifiers.
    func prepareInvocation<InferenceType: Inference>(
        _ inference: InferenceType.Type,
        input: InferenceType.Input,
        realization: InferenceRealizationConfiguration
    ) throws -> PreparedInference<InferenceType.Output> {
        let adaptation = try prepare(
            inference, input: input, realization: realization
        )
        return PreparedInference(adaptation: adaptation) { response in
            try decode(inference, response: response)
        }
    }
}
