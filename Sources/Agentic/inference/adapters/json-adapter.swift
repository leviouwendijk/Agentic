/// Structured output on any text model: the schema natively where the
/// routed model enforces it, as an instruction otherwise (the broker chooses
/// per route). Parsing, typed decoding and repair are the native adapter's.
///
/// Use `NativeStructuredAdapter` when the provider must enforce the schema.
public struct JSONAdapter:
    InferenceAdapter,
    InferenceOutputRepairing,
    InferenceRecoveryClassifying,
    Sendable
{
    public let identifier: InferenceAdapterIdentifier
    private let structured: NativeStructuredAdapter

    public init(
        identifier: InferenceAdapterIdentifier = .json
    ) {
        self.identifier = identifier
        self.structured = NativeStructuredAdapter(identifier: identifier)
    }

    public func prepare<InferenceType: Inference>(
        _ inference: InferenceType.Type,
        input: InferenceType.Input,
        realization: InferenceRealizationConfiguration
    ) throws -> InferenceAdaptation {
        flexible(try structured.prepare(inference, input: input, realization: realization))
    }

    public func decode<InferenceType: Inference>(
        _ inference: InferenceType.Type,
        response: AgentResponse
    ) throws -> InferenceType.Output {
        try structured.decode(inference, response: response)
    }

    public func repair<InferenceType: Inference>(
        _ inference: InferenceType.Type,
        input: InferenceType.Input,
        response: AgentResponse,
        error: any Error,
        realization: InferenceRealizationConfiguration
    ) throws -> InferenceAdaptation {
        flexible(try structured.repair(
            inference, input: input, response: response, error: error, realization: realization
        ))
    }

    public func incident(
        for error: any Error,
        stage: Recovery.Stage,
        inference: InferenceIdentifier,
        attemptIndex: Int,
        invocationIndex: Int
    ) -> Recovery.Incident? {
        structured.incident(
            for: error, stage: stage, inference: inference,
            attemptIndex: attemptIndex, invocationIndex: invocationIndex
        )
    }

    /// The schema stays the request's format; only the hard requirement
    /// goes, so routing keeps the purpose's model.
    private func flexible(
        _ adaptation: InferenceAdaptation
    ) -> InferenceAdaptation {
        var adaptation = adaptation
        adaptation.requirements.capabilities.remove(.structured_output)
        return adaptation
    }
}
