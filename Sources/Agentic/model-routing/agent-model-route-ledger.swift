import Foundation

public protocol AgentModelRouteLedger: Sendable {
    func record(
        _ record: AgentModelRouteRecord
    ) async throws
}

public struct AgentModelRouteRecord: Sendable, Codable, Hashable, Identifiable {
    public let id: String
    public let route: AgentModelRoute
    public let reasons: [String]
    public let warnings: [String]
    public let requestMetadata: [String: String]
    public let responseMetadata: [String: String]
    public let usage: AgentUsage?
    public let createdAt: Date

    public init(
        id: String = UUID().uuidString,
        route: AgentModelRoute,
        reasons: [String] = [],
        warnings: [String] = [],
        requestMetadata: [String: String] = [:],
        responseMetadata: [String: String] = [:],
        usage: AgentUsage? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.route = route
        self.reasons = reasons
        self.warnings = warnings
        self.requestMetadata = requestMetadata
        self.responseMetadata = responseMetadata
        self.usage = usage
        self.createdAt = createdAt
    }
}

public actor MemoryAgentModelRouteLedger: AgentModelRouteLedger {
    private var records: [AgentModelRouteRecord]

    public init(
        records: [AgentModelRouteRecord] = []
    ) {
        self.records = records
    }

    public func record(
        _ record: AgentModelRouteRecord
    ) async throws {
        records.append(
            record
        )
    }

    public func list() -> [AgentModelRouteRecord] {
        records
    }
}
