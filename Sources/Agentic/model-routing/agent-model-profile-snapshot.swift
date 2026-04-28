import Foundation

public struct AgentModelProfileSourceIdentifier: Sendable, Codable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
    public var rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public init(
        stringLiteral value: String
    ) {
        self.init(
            rawValue: value
        )
    }

    public init(
        _ value: String
    ) {
        self.init(
            rawValue: value
        )
    }
}

public struct AgentModelProfileSnapshot: Sendable, Codable, Hashable {
    public var source: AgentModelProfileSourceIdentifier
    public var createdAt: Date
    public var profiles: [AgentModelProfile]
    public var metadata: [String: String]

    public init(
        source: AgentModelProfileSourceIdentifier,
        createdAt: Date = Date(),
        profiles: [AgentModelProfile],
        metadata: [String: String] = [:]
    ) {
        self.source = source
        self.createdAt = createdAt
        self.profiles = profiles
        self.metadata = metadata
    }
}

public struct SnapshotAgentModelProfileProvider: AgentModelProfileProvider {
    public var snapshot: AgentModelProfileSnapshot

    public init(
        snapshot: AgentModelProfileSnapshot
    ) {
        self.snapshot = snapshot
    }

    public func profiles() throws -> [AgentModelProfile] {
        snapshot.profiles
    }
}

public extension AgentModelProfileSnapshot {
    var provider: SnapshotAgentModelProfileProvider {
        .init(
            snapshot: self
        )
    }
}

public extension AgentModelProfileCatalog {
    init(
        snapshot: AgentModelProfileSnapshot
    ) throws {
        try self.init(
            profiles: snapshot.profiles
        )
    }

    init(
        snapshots: [AgentModelProfileSnapshot]
    ) throws {
        try self.init(
            profiles: snapshots.flatMap(\.profiles)
        )
    }
}
