import Foundation
import Macros
import Schema

/// Where a constraint's authority comes from. A claim does not become an
/// invariant by being stored.
@JSONSchema
public enum AgentTaskConstraintProvenance: String, Sendable, Codable, Hashable, CaseIterable {
    /// The user stated it. An invariant.
    case user_instruction
    /// The coordinator settled it. An invariant until the coordinator reopens it.
    case accepted_decision
    /// Someone inspected it. A claim that may prove wrong.
    case observed
    /// Assumed, not verified. A claim to check.
    case hypothesis

    /// Whether a result must respect this constraint rather than test it.
    public var isInvariant: Bool {
        switch self {
        case .user_instruction, .accepted_decision:
            true
        case .observed, .hypothesis:
            false
        }
    }
}

/// One statement a result must respect, with the authority behind it.
@JSONSchema
public struct AgentTaskConstraint: Sendable, Codable, Hashable {
    /// The constraint itself, stated so it can be checked.
    public let statement: String
    /// Where the constraint's authority comes from.
    public let provenance: AgentTaskConstraintProvenance

    public init(
        statement: String,
        provenance: AgentTaskConstraintProvenance
    ) {
        self.statement = statement
        self.provenance = provenance
    }
}

/// The binding description of one bounded assignment: what to change, where
/// it may write, what it must preserve, and how its result will be judged.
@JSONSchema
public struct AgentTaskContract: Sendable, Codable, Hashable {
    /// The change to make and its expected outcome.
    public let objective: String
    /// The only paths that may be mutated. Empty means inspect and report only.
    public let writeScope: [String]
    /// Statements the result must respect, each with its provenance.
    public let constraints: [AgentTaskConstraint]
    /// Locations likely to need change; discovered, not exhaustive.
    public let candidateSites: [String]
    /// Related work that is out of scope, even if adjacent.
    public let exclusions: [String]
    /// Conditions the result is judged against before the task is accepted.
    public let acceptance: [String]

    public init(
        objective: String,
        writeScope: [String] = [],
        constraints: [AgentTaskConstraint] = [],
        candidateSites: [String] = [],
        exclusions: [String] = [],
        acceptance: [String] = []
    ) {
        self.objective = objective
        self.writeScope = writeScope
        self.constraints = constraints
        self.candidateSites = candidateSites
        self.exclusions = exclusions
        self.acceptance = acceptance
    }

    private enum CodingKeys: String, CodingKey {
        case objective
        case writeScope
        case constraints
        case candidateSites
        case exclusions
        case acceptance
    }
}

public extension AgentTaskContract {
    // Models often omit empty lists; only the objective is essential.
    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            objective: try values.decode(String.self, forKey: .objective),
            writeScope: try values.decodeIfPresent([String].self, forKey: .writeScope) ?? [],
            constraints: try values.decodeIfPresent([AgentTaskConstraint].self, forKey: .constraints) ?? [],
            candidateSites: try values.decodeIfPresent([String].self, forKey: .candidateSites) ?? [],
            exclusions: try values.decodeIfPresent([String].self, forKey: .exclusions) ?? [],
            acceptance: try values.decodeIfPresent([String].self, forKey: .acceptance) ?? []
        )
    }
}

/// What execution evidence shows about an attempt's mutations.
@JSONSchema
public enum AgentTaskMutationState: String, Sendable, Codable, Hashable, CaseIterable {
    /// Nothing was mutated.
    case none
    /// Mutations were applied to the workspace.
    case applied
    /// Mutations were prepared and await review before they apply.
    case pending_review
    /// Mutations were attempted and failed.
    case failed
}

/// What an assignee reports about one attempt. It is evidence for an
/// acceptance decision, not the decision itself.
@JSONSchema
public struct AgentTaskAttemptReport: Sendable, Codable, Hashable {
    /// What was done, concisely.
    public let summary: String
    /// Files actually mutated, not files intended to be.
    public let changedFiles: [String]
    /// The state of the attempt's mutations, by execution evidence.
    public let mutationState: AgentTaskMutationState
    /// Remaining dependencies or blockers.
    public let unresolved: [String]
    /// Contract assumptions the attempt found to be wrong: an invariant that
    /// cannot hold, a needed change outside the write scope, a claim that
    /// proved false. A non-empty list asks the coordinator to reopen the
    /// contract instead of accepting a workaround.
    public let contractConflicts: [String]

    public init(
        summary: String,
        changedFiles: [String] = [],
        mutationState: AgentTaskMutationState = .none,
        unresolved: [String] = [],
        contractConflicts: [String] = []
    ) {
        self.summary = summary
        self.changedFiles = changedFiles
        self.mutationState = mutationState
        self.unresolved = unresolved
        self.contractConflicts = contractConflicts
    }

    private enum CodingKeys: String, CodingKey {
        case summary
        case changedFiles
        case mutationState
        case unresolved
        case contractConflicts
    }
}

public extension AgentTaskAttemptReport {
    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            summary: try values.decode(String.self, forKey: .summary),
            changedFiles: try values.decodeIfPresent([String].self, forKey: .changedFiles) ?? [],
            mutationState: try values.decodeIfPresent(AgentTaskMutationState.self, forKey: .mutationState) ?? .none,
            unresolved: try values.decodeIfPresent([String].self, forKey: .unresolved) ?? [],
            contractConflicts: try values.decodeIfPresent([String].self, forKey: .contractConflicts) ?? []
        )
    }
}

@JSONSchema
public enum AgentTaskAttemptOutcome: String, Sendable, Codable, Hashable, CaseIterable {
    case submitted
    case accepted
    case rejected
    case failed
}

@JSONSchema
public struct AgentTaskAttempt: Sendable, Codable, Hashable {
    public let number: Int
    public let owner: String?
    public let report: AgentTaskAttemptReport
    public var outcome: AgentTaskAttemptOutcome
    /// Why the coordinator rejected or failed the attempt; carried into
    /// the next attempt instead of the whole history.
    public var decisionNote: String?
    public let recordedAt: Date
    public var decidedAt: Date?

    public init(
        number: Int,
        owner: String? = nil,
        report: AgentTaskAttemptReport,
        outcome: AgentTaskAttemptOutcome = .submitted,
        decisionNote: String? = nil,
        recordedAt: Date = Date(),
        decidedAt: Date? = nil
    ) {
        self.number = number
        self.owner = owner
        self.report = report
        self.outcome = outcome
        self.decisionNote = decisionNote
        self.recordedAt = recordedAt
        self.decidedAt = decidedAt
    }
}

/// Session association for task tools, supplied by a trusted host.
public struct AgentTaskScope: Sendable, Hashable {
    public let sessionID: String?

    public init(
        sessionID: String?
    ) {
        self.sessionID = sessionID
    }
}
