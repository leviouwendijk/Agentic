import Primitives

public struct AgenticModeIdentifier: StringIdentifier {
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }
}

public enum BudgetPosture: String, Sendable, Codable, Hashable, CaseIterable {
    case minimal
    case constrained
    case balanced
    case generous
    case local_only
}

public enum ApprovalStrictness: String, Sendable, Codable, Hashable, CaseIterable {
    case strict
    case review_bounded_mutation
    case review_privileged
    case relaxed_observe
    case locked_down
}

public struct AgenticMode: Sendable, Codable, Hashable, Identifiable {
    public var id: AgenticModeIdentifier
    public var title: String
    public var routeDefaults: ModeRouteDefaults
    public var autonomyMode: AutonomyMode
    public var exposedToolIdentifiers: [AgentToolIdentifier]
    public var loadedSkillIdentifiers: [AgentSkillIdentifier]
    public var budgetPosture: BudgetPosture
    public var approvalStrictness: ApprovalStrictness
    public var metadata: [String: String]

    public init(
        id: AgenticModeIdentifier,
        title: String,
        routeDefaults: ModeRouteDefaults,
        autonomyMode: AutonomyMode,
        exposedToolIdentifiers: [AgentToolIdentifier] = [],
        loadedSkillIdentifiers: [AgentSkillIdentifier] = [],
        budgetPosture: BudgetPosture = .balanced,
        approvalStrictness: ApprovalStrictness = .review_privileged,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.title = title
        self.routeDefaults = routeDefaults
        self.autonomyMode = autonomyMode
        self.exposedToolIdentifiers = exposedToolIdentifiers
        self.loadedSkillIdentifiers = loadedSkillIdentifiers
        self.budgetPosture = budgetPosture
        self.approvalStrictness = approvalStrictness
        self.metadata = metadata
    }
}
