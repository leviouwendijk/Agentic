/// A named addition to what an Agent starts with, beyond what it declares.
/// The runtime applies each before the run's first request, where the
/// application installs its capabilities and its condition holds, and
/// records it as the source of what it added.
public enum AgentCapabilityGrant:
    String,
    Sendable,
    Codable,
    Hashable,
    CaseIterable
{
    /// Reading the owner's context.
    case ambient
    /// Listing, searching and inspecting capabilities.
    case discovery
    /// Reading back compacted history, in dynamic context mode.
    case session_readers
    /// `read_result`, when results can be shortened.
    case result_reader
}

/// The grants an Agent takes: all, unless it excludes some.
public struct AgentCapabilityGrants:
    Sendable,
    Codable,
    Hashable
{
    public let excluded: [AgentCapabilityGrant]

    public init(
        excluding excluded: [AgentCapabilityGrant] = []
    ) {
        self.excluded = AgentCapabilityGrant.allCases.filter(excluded.contains)
    }

    public static let standard = Self()

    /// Every grant but these; e.g. `.except(.discovery)` for a fixed worker.
    public static func except(
        _ excluded: AgentCapabilityGrant...
    ) -> Self {
        .init(excluding: excluded)
    }

    public func contains(
        _ grant: AgentCapabilityGrant
    ) -> Bool {
        !excluded.contains(grant)
    }

    public var granted: [AgentCapabilityGrant] {
        AgentCapabilityGrant.allCases.filter(contains)
    }
}
