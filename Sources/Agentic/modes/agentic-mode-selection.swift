public struct ModeOverlay: Sendable, Codable, Hashable {
    public var routeDefaults: ModeRouteDefaults?
    public var autonomyMode: AutonomyMode?
    public var exposedToolIdentifiers: [AgentToolIdentifier]?
    public var loadedSkillIdentifiers: [AgentSkillIdentifier]?
    public var budgetPosture: BudgetPosture?
    public var approvalStrictness: ApprovalStrictness?
    public var metadata: [String: String]

    public init(
        routeDefaults: ModeRouteDefaults? = nil,
        autonomyMode: AutonomyMode? = nil,
        exposedToolIdentifiers: [AgentToolIdentifier]? = nil,
        loadedSkillIdentifiers: [AgentSkillIdentifier]? = nil,
        budgetPosture: BudgetPosture? = nil,
        approvalStrictness: ApprovalStrictness? = nil,
        metadata: [String: String] = [:]
    ) {
        self.routeDefaults = routeDefaults
        self.autonomyMode = autonomyMode
        self.exposedToolIdentifiers = exposedToolIdentifiers
        self.loadedSkillIdentifiers = loadedSkillIdentifiers
        self.budgetPosture = budgetPosture
        self.approvalStrictness = approvalStrictness
        self.metadata = metadata
    }

    public func apply(
        to mode: AgenticMode
    ) -> AgenticMode {
        var copy = mode

        if let routeDefaults {
            copy.routeDefaults = routeDefaults
        }

        if let autonomyMode {
            copy.autonomyMode = autonomyMode
        }

        if let exposedToolIdentifiers {
            copy.exposedToolIdentifiers = exposedToolIdentifiers
        }

        if let loadedSkillIdentifiers {
            copy.loadedSkillIdentifiers = loadedSkillIdentifiers
        }

        if let budgetPosture {
            copy.budgetPosture = budgetPosture
        }

        if let approvalStrictness {
            copy.approvalStrictness = approvalStrictness
        }

        copy.metadata.merge(
            metadata
        ) { _, new in
            new
        }

        return copy
    }
}

public struct ModeSelection: Sendable, Codable, Hashable {
    public var modeID: AgenticModeIdentifier
    public var mode: AgenticMode
    public var configuration: AgentRunnerConfiguration
    public var routeDefaults: ModeRouteDefaults
    public var routePolicy: AgentModelUsePolicy
    public var exposedToolIdentifiers: [AgentToolIdentifier]
    public var loadedSkillIdentifiers: [AgentSkillIdentifier]
    public var budgetPosture: BudgetPosture
    public var approvalStrictness: ApprovalStrictness
    public var metadata: [String: String]

    public init(
        mode: AgenticMode,
        baseConfiguration: AgentRunnerConfiguration = .default,
        overlay: ModeOverlay = .init()
    ) {
        let mode = overlay.apply(
            to: mode
        )
        var configuration = baseConfiguration
        configuration.autonomyMode = mode.autonomyMode

        self.modeID = mode.id
        self.mode = mode
        self.configuration = configuration
        self.routeDefaults = mode.routeDefaults
        self.routePolicy = mode.routeDefaults.primaryPolicy
        self.exposedToolIdentifiers = mode.exposedToolIdentifiers
        self.loadedSkillIdentifiers = mode.loadedSkillIdentifiers
        self.budgetPosture = mode.budgetPosture
        self.approvalStrictness = mode.approvalStrictness
        self.metadata = mode.metadata
    }

    public func routePolicy(
        for purpose: AgentModelRoutePurpose
    ) -> AgentModelUsePolicy {
        routeDefaults.policy(
            for: purpose
        )
    }
}
