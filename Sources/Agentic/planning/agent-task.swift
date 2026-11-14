import Foundation
import Macros
import Primitives
import Schema

public struct AgentTaskIdentifier:
    StringIdentifier,
    JSONSchemaProviding
{
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public static var jsonschema: JSONSchema {
        .string()
    }
}

/// `completed` is acceptance: only an accepted task clears its dependents.
/// A worker finishing an attempt moves the task to `awaiting_acceptance`;
/// its claim alone never establishes completion.
@JSONSchema
public enum AgentTaskStatus: String, Sendable, Codable, Hashable, CaseIterable {
    case pending
    case processing
    case awaiting_acceptance
    case completed
    case failed
    case cancelled
}

@JSONSchema
public struct AgentTask: Sendable, Codable, Hashable, Identifiable {
    public let id: AgentTaskIdentifier
    public var subject: String
    public var description: String
    public var status: AgentTaskStatus
    public var owner: String?
    public var blockedBy: [AgentTaskIdentifier]
    public var sessionID: String?
    public var contract: AgentTaskContract?
    public var attempts: [AgentTaskAttempt]
    public var createdAt: Date
    public var updatedAt: Date
    public var metadata: [String: String]

    public init(
        id: AgentTaskIdentifier = .init(UUID().uuidString),
        subject: String,
        description: String = "",
        status: AgentTaskStatus = .pending,
        owner: String? = nil,
        blockedBy: [AgentTaskIdentifier] = [],
        sessionID: String? = nil,
        contract: AgentTaskContract? = nil,
        attempts: [AgentTaskAttempt] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.subject = subject
        self.description = description
        self.status = status
        self.owner = owner
        self.blockedBy = blockedBy
        self.sessionID = sessionID
        self.contract = contract
        self.attempts = attempts
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.metadata = metadata
    }

    public var isReady: Bool {
        status == .pending && blockedBy.isEmpty
    }

    public var isBlocked: Bool {
        status == .pending && !blockedBy.isEmpty
    }

    public var latestAttempt: AgentTaskAttempt? {
        attempts.last
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case subject
        case description
        case status
        case owner
        case blockedBy
        case sessionID
        case contract
        case attempts
        case createdAt
        case updatedAt
        case metadata
    }
}

public extension AgentTask {
    // Task files written before contracts and attempts existed stay readable.
    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try values.decode(AgentTaskIdentifier.self, forKey: .id),
            subject: try values.decode(String.self, forKey: .subject),
            description: try values.decodeIfPresent(String.self, forKey: .description) ?? "",
            status: try values.decode(AgentTaskStatus.self, forKey: .status),
            owner: try values.decodeIfPresent(String.self, forKey: .owner),
            blockedBy: try values.decodeIfPresent([AgentTaskIdentifier].self, forKey: .blockedBy) ?? [],
            sessionID: try values.decodeIfPresent(String.self, forKey: .sessionID),
            contract: try values.decodeIfPresent(AgentTaskContract.self, forKey: .contract),
            attempts: try values.decodeIfPresent([AgentTaskAttempt].self, forKey: .attempts) ?? [],
            createdAt: try values.decode(Date.self, forKey: .createdAt),
            updatedAt: try values.decode(Date.self, forKey: .updatedAt),
            metadata: try values.decodeIfPresent([String: String].self, forKey: .metadata) ?? [:]
        )
    }
}
