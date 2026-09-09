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
    public var selection: AgentModelSelection
    public var metadata: [String: String]

    public init(
        selection: AgentModelSelection,
        metadata: [String: String] = [:]
    ) {
        self.selection = selection
        self.metadata = metadata
    }
}

public struct AgentModelRouteResult: Sendable, Codable, Hashable {
    public var route: AgentModelRoute
    public var diagnostics: [AgentModelSelectionDiagnostic]

    public init(
        route: AgentModelRoute,
        diagnostics: [AgentModelSelectionDiagnostic] = []
    ) {
        self.route = route
        self.diagnostics = diagnostics
    }
}
