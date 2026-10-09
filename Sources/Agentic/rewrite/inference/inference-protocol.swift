public protocol Inference: Capability
where DefinitionType == InferenceDefinition
{

    static func specification(
        for input: Input
    ) throws -> InferenceSpecification<Output>
}

public extension Inference {
    static func specification(
        for input: Input
    ) throws -> InferenceSpecification<Output> {
        .generative
    }
}
