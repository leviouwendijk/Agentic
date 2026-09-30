public protocol Inference: Producer {
    static var definition: InferenceDefinition { get }

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
