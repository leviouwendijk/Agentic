import Foundation
import Macros
import Schema

/// Where a constraint's authority comes from. A model-generated claim
/// (`observed`, `hypothesis`) never becomes an invariant by being stored.
@JSONSchema
public enum AgentTaskConstraintProvenance: String, Sendable, Codable, Hashable, CaseIterable {
    case user_instruction
    case accepted_decision
    case observed
    case hypothesis
}

@JSONSchema
public struct AgentTaskConstraint: Sendable, Codable, Hashable {
    public let statement: String
    public let provenance: AgentTaskConstraintProvenance

    public init(
        statement: String,
        provenance: AgentTaskConstraintProvenance
    ) {
        self.statement = statement
        self.provenance = provenance
    }
}

/// The bounded assignment a task carries: what to change, where it may
/// write, what it must preserve, and how its result will be judged.
@JSONSchema
public struct AgentTaskContract: Sendable, Codable, Hashable {
    public let objective: String
    /// Paths the assignee may mutate. Empty means no mutation is expected.
    public let writeScope: [String]
    public let constraints: [AgentTaskConstraint]
    /// Discovered locations likely to need change; not exhaustive.
    public let candidateSites: [String]
    public let exclusions: [String]
    /// Conditions the result must meet before the task is accepted.
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

@JSONSchema
public enum AgentTaskMutationState: String, Sendable, Codable, Hashable, CaseIterable {
    case none
    case applied
    case pending_review
    case failed
}

/// What an assignee reports about one attempt. It is evidence for an
/// acceptance decision, not the decision itself.
@JSONSchema
public struct AgentTaskAttemptReport: Sendable, Codable, Hashable {
    public let summary: String
    public let changedFiles: [String]
    public let mutationState: AgentTaskMutationState
    public let unresolved: [String]
    /// Assumptions in the contract the attempt found to be wrong. A
    /// non-empty list asks the coordinator to reopen the contract.
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
