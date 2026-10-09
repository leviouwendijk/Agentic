/// A domain adapter bound to one authored Inference type.
/// No manually maintained list of identifiers or model providers is needed.
public protocol InferenceAdapterFor: Sendable {
    associatedtype Target: Inference
    var identifier: InferenceAdapterIdentifier { get }

    func prepare(
        input: Target.Input,
        realization: InferenceRealizationConfiguration
    ) throws -> PreparedInference<Target.Output>
}

public enum TypedInferenceAdapterError: Error, Sendable, Equatable {
    case incompatibleInference(
        adapter: InferenceAdapterIdentifier,
        expected: InferenceIdentifier,
        received: InferenceIdentifier
    )
}

/// Erases a single-Inference adapter at the catalog boundary, retaining typed
/// preparation and its per-invocation decoder inside the erased implementation.
public struct TypedInferenceAdapter<Wrapped: InferenceAdapterFor>:
    InferenceAdapter, Sendable
{
    public let wrapped: Wrapped
    public var identifier: InferenceAdapterIdentifier { wrapped.identifier }

    public init(_ wrapped: Wrapped) { self.wrapped = wrapped }

    public func prepareInvocation<I: Inference>(
        _ inference: I.Type,
        input: I.Input,
        realization: InferenceRealizationConfiguration
    ) throws -> PreparedInference<I.Output> {
        guard I.self == Wrapped.Target.self,
              let typedInput = input as? Wrapped.Target.Input
        else {
            throw TypedInferenceAdapterError.incompatibleInference(
                adapter: identifier,
                expected: Wrapped.Target.definition.identifier,
                received: I.definition.identifier
            )
        }
        let prepared = try wrapped.prepare(
            input: typedInput, realization: realization
        )
        return PreparedInference<I.Output>(adaptation: prepared.adaptation) { response in
            let output = try prepared.decode(response)
            // The metatype identity was checked above; this cast is the
            // existential-to-generic boundary, not user-supplied schema coercion.
            guard let output = output as? I.Output else {
                throw TypedInferenceAdapterError.incompatibleInference(
                    adapter: identifier,
                    expected: Wrapped.Target.definition.identifier,
                    received: I.definition.identifier
                )
            }
            return output
        }
    }

    public func prepare<I: Inference>(
        _ inference: I.Type,
        input: I.Input,
        realization: InferenceRealizationConfiguration
    ) throws -> InferenceAdaptation {
        try prepareInvocation(
            inference, input: input, realization: realization
        ).adaptation
    }

    public func decode<I: Inference>(
        _ inference: I.Type,
        response: AgentResponse
    ) throws -> I.Output {
        // A targeted adapter's decoder depends on the input-specific preparation.
        // Invocation execution MUST call prepareInvocation, not this legacy method.
        throw TypedInferenceAdapterError.incompatibleInference(
            adapter: identifier,
            expected: Wrapped.Target.definition.identifier,
            received: I.definition.identifier
        )
    }
}
