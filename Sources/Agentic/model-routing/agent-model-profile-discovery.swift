public enum AgentModelProfileDiscoveryRefreshReason: String, Sendable, Codable, Hashable, CaseIterable {
    case startup
    case manual
    case stale_snapshot
    case provider_changed
    case cache_missing
}

public struct AgentModelProfileDiscoveryRequest: Sendable, Codable, Hashable {
    public var reason: AgentModelProfileDiscoveryRefreshReason
    public var metadata: [String: String]

    public init(
        reason: AgentModelProfileDiscoveryRefreshReason = .manual,
        metadata: [String: String] = [:]
    ) {
        self.reason = reason
        self.metadata = metadata
    }

    public static let manual = Self(
        reason: .manual
    )
}

/// Deferred generic seam for dynamic provider discovery.
///
/// Keep normal routing on `AgentModelProfileProvider` and `AgentModelProfileCatalog`.
/// This protocol exists so provider targets such as AgenticAWS, future AgenticOpenAI,
/// AgenticAnthropic, AgenticOllama, or local registry-backed providers can converge
/// on one refresh/snapshot shape later.
///
/// Do not make the broker call discovery during routing. Discovery is for host setup,
/// cache refresh, CLIs, diagnostics, and provider maintenance.
public protocol AgentModelProfileDiscovery: Sendable {
    var source: AgentModelProfileSourceIdentifier { get }

    func snapshot(
        request: AgentModelProfileDiscoveryRequest
    ) async throws -> AgentModelProfileSnapshot
}

public extension AgentModelProfileDiscovery {
    func snapshot() async throws -> AgentModelProfileSnapshot {
        try await snapshot(
            request: .manual
        )
    }

    func profileProvider(
        request: AgentModelProfileDiscoveryRequest = .manual
    ) async throws -> SnapshotAgentModelProfileProvider {
        try await snapshot(
            request: request
        ).provider
    }
}
