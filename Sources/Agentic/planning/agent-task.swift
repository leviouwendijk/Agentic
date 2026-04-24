import Foundation

public struct AgentTaskIdentifier: Sendable, Codable, Hashable, RawRepresentable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public init(
        _ rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public init(
        stringLiteral value: StringLiteralType
    ) {
        self.rawValue = value
    }

    public var description: String {
        rawValue
    }
}

public enum AgentTaskStatus: String, Sendable, Codable, Hashable, CaseIterable {
    case pending
    case processing
    case completed
    case cancelled
}

public struct AgentTask: Sendable, Codable, Hashable, Identifiable {
    public let id: AgentTaskIdentifier
    public var subject: String
    public var description: String
    public var status: AgentTaskStatus
    public var owner: String?
    public var blockedBy: [AgentTaskIdentifier]
    public var sessionID: String?
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
}
