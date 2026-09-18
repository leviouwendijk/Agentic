public enum ActionRisk: String, Sendable, Codable, Hashable, CaseIterable {
    case observe
    case boundedmutate
    case privileged
    case forbidden
}

public extension ActionRisk {
    var isMutating: Bool {
        switch self {
        case .observe:
            return false

        case .boundedmutate, .privileged, .forbidden:
            return true
        }
    }

    var defaultSideEffects: [String] {
        switch self {
        case .observe:
            return []

        case .boundedmutate:
            return [
                "bounded mutation"
            ]

        case .privileged:
            return [
                "privileged operation"
            ]

        case .forbidden:
            return [
                "forbidden action"
            ]
        }
    }
}
