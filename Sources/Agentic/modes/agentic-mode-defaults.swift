public struct ModeRouteDefaults: Sendable, Codable, Hashable {
    public var primaryPurpose: AgentModelRoutePurpose
    public var policies: [AgentModelRoutePurpose: AgentModelUsePolicy]

    public init(
        primaryPurpose: AgentModelRoutePurpose,
        policies: [AgentModelRoutePurpose: AgentModelUsePolicy] = [:]
    ) {
        self.primaryPurpose = primaryPurpose
        self.policies = policies
    }

    public var primaryPolicy: AgentModelUsePolicy {
        policy(
            for: primaryPurpose
        )
    }

    public func policy(
        for purpose: AgentModelRoutePurpose
    ) -> AgentModelUsePolicy {
        if let policy = policies[purpose] {
            return policy
        }

        return .init(
            purpose: purpose
        )
    }
}

public extension AgenticModeIdentifier {
    static let planning: Self = "planning"
    static let research: Self = "research"
    static let coder: Self = "coder"
    static let review: Self = "review"
    static let debugging: Self = "debugging"
    static let cheap_utility: Self = "cheap_utility"
    static let `private`: Self = "private"
}
