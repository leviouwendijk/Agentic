import Foundation

public struct AgentModelRoute: Sendable, Codable, Hashable {
    public var purpose: AgentModelRoutePurpose
    public var profile: AgentModelProfile
    public var selectedAt: Date
    public var metadata: [String: String]

    public init(
        purpose: AgentModelRoutePurpose,
        profile: AgentModelProfile,
        selectedAt: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.purpose = purpose
        self.profile = profile
        self.selectedAt = selectedAt
        self.metadata = metadata
    }
}

public struct AgentModelRouteRequest: Sendable, Codable, Hashable {
    public var request: AgentRequest
    public var policy: AgentModelUsePolicy
    public var metadata: [String: String]

    public init(
        request: AgentRequest,
        policy: AgentModelUsePolicy,
        metadata: [String: String] = [:]
    ) {
        self.request = request
        self.policy = policy
        self.metadata = metadata
    }
}

public struct AgentModelRouteResult: Sendable, Codable, Hashable {
    public var route: AgentModelRoute
    public var reasons: [String]
    public var warnings: [String]

    public init(
        route: AgentModelRoute,
        reasons: [String] = [],
        warnings: [String] = []
    ) {
        self.route = route
        self.reasons = reasons
        self.warnings = warnings
    }
}
