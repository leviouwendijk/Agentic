public struct ModeOverlay: Sendable, Codable, Hashable {
    public var routeDefaults: ModeRouteDefaults?
    public var autonomyMode: AutonomyMode?
    public var loadedInstructionIdentifiers: [InstructionIdentifier]?
    public var budgetPosture: BudgetPosture?
    public var approvalStrictness: ApprovalStrictness?
    public var metadata: [String: String]

    public init(
        routeDefaults: ModeRouteDefaults? = nil,
        autonomyMode: AutonomyMode? = nil,
        loadedInstructionIdentifiers: [InstructionIdentifier]? = nil,
        budgetPosture: BudgetPosture? = nil,
        approvalStrictness: ApprovalStrictness? = nil,
        metadata: [String: String] = [:]
    ) {
        self.routeDefaults = routeDefaults
        self.autonomyMode = autonomyMode
        self.loadedInstructionIdentifiers = loadedInstructionIdentifiers
        self.budgetPosture = budgetPosture
        self.approvalStrictness = approvalStrictness
        self.metadata = metadata
    }

    public func apply(
        to mode: Mode
    ) -> Mode {
        var copy = mode

        if let routeDefaults {
            copy.routeDefaults = routeDefaults
        }

        if let autonomyMode {
            copy.autonomyMode = autonomyMode
        }

        if let loadedInstructionIdentifiers {
            copy.loadedInstructionIdentifiers = loadedInstructionIdentifiers
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
    public var mode: Mode

    public init(
        mode: Mode,
        overlay: ModeOverlay = .init()
    ) {
        self.mode = overlay.apply(
            to: mode
        )
    }

    public var modeID: ModeIdentifier {
        mode.id
    }

    public var routeDefaults: ModeRouteDefaults {
        mode.routeDefaults
    }

    public var modelSelection: AgentModelSelection {
        mode.routeDefaults.primarySelection
    }

    public var loadedInstructionIdentifiers: [InstructionIdentifier] {
        mode.loadedInstructionIdentifiers
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

    public func modelSelection(
        for purpose: AgentModelRoutePurpose
    ) -> AgentModelSelection {
        mode.routeDefaults.selection(
            for: purpose
        )
    }
}
