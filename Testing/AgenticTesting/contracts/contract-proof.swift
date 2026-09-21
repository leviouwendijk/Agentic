import Agentic

public enum ContractProofError:
    Error,
    Sendable,
    Equatable
{
    case identifierMismatch(
        expected: String,
        actual: String
    )
}

public enum ContractProof {
    public static func domain<Value: Domain>(
        _: Value.Type
    ) {}

    public static func agent<Value: Agent>(
        _: Value.Type
    ) {}

    public static func inference<Value: Inference>(
        _: Value.Type
    ) {}

    public static func program<Value: Program>(
        _: Value.Type
    ) {}

    public static func tool<Value: Tool>(
        _: Value.Type
    ) {}

    public static func source<Value: Source>(
        _: Value.Type
    ) {}

    public static func result<Value: Result>(
        _: Value.Type
    ) {}

    public static func inferenceRealization<Value: InferenceRealization>(
        _: Value.Type
    ) {}

    public static func optimization<Value: Optimization>(
        _: Value.Type
    ) {}

    public static func inferenceSite<
        ProgramType: Program,
        InferenceType: Inference
    >(
        _: InferenceSite<ProgramType, InferenceType>,
        program _: ProgramType.Type,
        inference _: InferenceType.Type
    ) {}

    public static func identifier(
        _ actual: String,
        expected: String
    ) throws {
        guard actual == expected else {
            throw ContractProofError.identifierMismatch(
                expected: expected,
                actual: actual
            )
        }
    }
}
