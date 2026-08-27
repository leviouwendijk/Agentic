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
    public var mode: AgenticMode

    public init(
        mode: AgenticMode,
        overlay: ModeOverlay = .init()
    ) {
        self.mode = overlay.apply(
            to: mode
        )
    }

    public var modeID: AgenticModeIdentifier {
        mode.id
    }

    public var routeDefaults: ModeRouteDefaults {
        mode.routeDefaults
    }

    public var routePolicy: AgentModelUsePolicy {
        mode.routeDefaults.primaryPolicy
    }

    public var exposedToolIdentifiers: [AgentToolIdentifier] {
        mode.exposedToolIdentifiers
    }

    public var loadedSkillIdentifiers: [AgentSkillIdentifier] {
        mode.loadedSkillIdentifiers
    }

    public var budgetPosture: BudgetPosture {
        mode.budgetPosture
    }

    public var approvalStrictness: ApprovalStrictness {
        mode.approvalStrictness
    }

    public var metadata: [String: String] {
        mode.metadata
    }

    public func routePolicy(
        for purpose: AgentModelRoutePurpose
    ) -> AgentModelUsePolicy {
        mode.routeDefaults.policy(
            for: purpose
        )
    }
}
