public struct ModeRouteDefaults: Sendable, Codable, Hashable {
    public var primaryPurpose: AgentModelRoutePurpose
    public var selections: [AgentModelRoutePurpose: AgentModelSelection]

    public init(
        primaryPurpose: AgentModelRoutePurpose,
        selections: [AgentModelRoutePurpose: AgentModelSelection] = [:]
    ) {
        self.primaryPurpose = primaryPurpose
        self.selections = selections
    }

    public var primarySelection: AgentModelSelection {
        selection(
            for: primaryPurpose
        )
    }

    public func selection(
        for purpose: AgentModelRoutePurpose
    ) -> AgentModelSelection {
        if let selection = selections[purpose] {
            return selection
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
