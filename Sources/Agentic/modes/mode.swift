import Primitives

public struct ModeIdentifier: StringIdentifier {
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

public struct Mode: Sendable, Codable, Hashable, Identifiable {
    public var id: ModeIdentifier
    public var title: String
    public var routeDefaults: ModeRouteDefaults
    public var autonomyMode: AutonomyMode
    public var loadedInstructionIdentifiers: [InstructionIdentifier]
    public var budgetPosture: BudgetPosture
    public var approvalStrictness: ApprovalStrictness
    public var metadata: [String: String]

    public init(
        id: ModeIdentifier,
        title: String,
        routeDefaults: ModeRouteDefaults,
        autonomyMode: AutonomyMode,
        loadedInstructionIdentifiers: [InstructionIdentifier] = [],
        budgetPosture: BudgetPosture = .balanced,
        approvalStrictness: ApprovalStrictness = .review_privileged,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.title = title
        self.routeDefaults = routeDefaults
        self.autonomyMode = autonomyMode
        self.loadedInstructionIdentifiers = loadedInstructionIdentifiers
        self.budgetPosture = budgetPosture
        self.approvalStrictness = approvalStrictness
        self.metadata = metadata
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, routeDefaults, autonomyMode
        case loadedInstructionIdentifiers
        case budgetPosture, approvalStrictness, metadata
    }

    /// Preserve decoding of Modes serialized before Instruction selection existed.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(ModeIdentifier.self, forKey: .id),
            title: try container.decode(String.self, forKey: .title),
            routeDefaults: try container.decode(ModeRouteDefaults.self, forKey: .routeDefaults),
            autonomyMode: try container.decode(AutonomyMode.self, forKey: .autonomyMode),
            loadedInstructionIdentifiers: try container.decodeIfPresent([InstructionIdentifier].self, forKey: .loadedInstructionIdentifiers) ?? [],
            budgetPosture: try container.decodeIfPresent(BudgetPosture.self, forKey: .budgetPosture) ?? .balanced,
            approvalStrictness: try container.decodeIfPresent(ApprovalStrictness.self, forKey: .approvalStrictness) ?? .review_privileged,
            metadata: try container.decodeIfPresent([String: String].self, forKey: .metadata) ?? [:]
        )
    }
}
