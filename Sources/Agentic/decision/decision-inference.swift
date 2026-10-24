public protocol DecisionInference: Inference {
    static func decision(
        for input: Input
    ) throws -> Decision.Specification<Output>
}

public extension DecisionInference {
    static func specification(
        for input: Input
    ) throws -> InferenceSpecification<Output> {
        .decision(
            try decision(for: input)
        )
    }
}
