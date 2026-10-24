public enum InferenceSpecification<Output: Sendable>: Sendable {
    case generative
    case decision(Decision.Specification<Output>)
}

public extension InferenceSpecification {
    var operation: AgentModelOperation {
        switch self {
        case .generative:
            .generation
        case .decision:
            .decision
        }
    }
}
