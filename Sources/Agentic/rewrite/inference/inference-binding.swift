import Primitives
import Schema

/// A resolved typed Inference, preparing invocations without performing model calls.
public struct InferenceBinding: CapabilityBinding {
    public let definition: InferenceDefinition
    public let capabilityContract: CapabilityContract
    public let defaultRealization: InferenceRealizationConfiguration?

    private let prepareHandler: @Sendable (
        JSONValue,
        InferenceRealizationConfiguration,
        InferenceExecutionContext
    ) throws -> InferenceInvocation

    public init<I: Inference>(
        _ inference: I.Type,
        defaultRealization: InferenceRealizationConfiguration? = nil
    ) {
        self.definition = I.definition
        self.capabilityContract = I.contract
        self.defaultRealization = defaultRealization
        self.prepareHandler = { input, realization, context in
            try I.invocation(
                input: JSONCoding.default.decode(I.Input.self, from: input),
                realization: realization,
                context: context
            )
        }
    }

    public var reference: CapabilityReference {
        .inference(definition.identifier)
    }

    public var identifier: InferenceIdentifier {
        definition.identifier
    }

    public var semanticInputSchema: JSONSchema {
        capabilityContract.input
    }

    public var semanticOutputSchema: JSONSchema {
        capabilityContract.output
    }

    public var modelFacingInputSchema: JSONSchema {
        CapabilityModelInputSchema.envelope(
            semanticInput: semanticInputSchema
        )
    }

    /// Called by an already resolved owner, where the typed inference identity
    /// is determined by this binding, rather than a provider-originated ID.
    public func invocation(
        input: JSONValue,
        realization: InferenceRealizationConfiguration? = nil,
        context: InferenceExecutionContext = .default
    ) throws -> InferenceInvocation {
        guard let realization = realization ?? defaultRealization else {
            throw InferenceBindingError.missingRealization(definition.identifier)
        }
        return try prepareHandler(input, realization, context)
    }

    /// A model-originated call must match the bound kind and identifier before
    /// its JSON payload is interpreted as the authored Input.
    public func invocation(
        from raw: CapabilityCall.Raw,
        realization: InferenceRealizationConfiguration? = nil,
        context: InferenceExecutionContext = .default
    ) throws -> InferenceInvocation {
        guard raw.capability == reference else {
            throw CapabilityRequestError.mismatchedCapability(
                expected: reference,
                actual: raw.capability
            )
        }
        return try invocation(input: raw.input, realization: realization, context: context)
    }
}

public enum InferenceBindingError: Error, Sendable, Equatable {
    case missingRealization(InferenceIdentifier)
}
