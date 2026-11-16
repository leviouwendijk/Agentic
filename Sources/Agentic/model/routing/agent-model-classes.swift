public enum AgentModelCostClass: String, Sendable, Codable, Hashable, CaseIterable {
    case free
    case cheap
    case balanced
    case expensive
    case premium

    public var rank: Int {
        switch self {
        case .free:
            return 0

        case .cheap:
            return 1

        case .balanced:
            return 2

        case .expensive:
            return 3

        case .premium:
            return 4
        }
    }
}

public enum AgentModelLatencyClass: String, Sendable, Codable, Hashable, CaseIterable {
    case low
    case medium
    case high

    public var rank: Int {
        switch self {
        case .low:
            return 0

        case .medium:
            return 1

        case .high:
            return 2
        }
    }
}

public enum AgentModelPrivacyClass: String, Sendable, Codable, Hashable, CaseIterable {
    case local_private
    case private_cloud
    case external_cloud

    public var rank: Int {
        switch self {
        case .external_cloud:
            return 0

        case .private_cloud:
            return 1

        case .local_private:
            return 2
        }
    }

    public var isExternal: Bool {
        self == .external_cloud
    }
}

/// What a model can be relied on for, independent of its cost and speed.
/// A declared, coarse judgement; measured results per task family belong to
/// benchmarks, not to this catalog.
public enum AgentModelTier: String, Sendable, Codable, Hashable, CaseIterable, Comparable {
    /// Short, simple, high-volume work; small local models.
    case light
    /// Routine coding and tool use.
    case standard
    /// Reliable multi-step agentic work, planning and review.
    case strong
    /// The best available: hardest reasoning, long autonomous work.
    case frontier

    public var rank: Int {
        switch self {
        case .light: 0
        case .standard: 1
        case .strong: 2
        case .frontier: 3
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rank < rhs.rank
    }
}
