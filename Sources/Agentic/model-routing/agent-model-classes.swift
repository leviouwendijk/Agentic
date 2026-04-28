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
