public struct AgentDelegationPolicy:
    Sendable,
    Codable,
    Hashable
{
    public struct Limits:
        Sendable,
        Codable,
        Hashable
    {
        public let depth: Int
        public let children: Int
        public let descendants: Int
        public let concurrentChildren: Int

        public init(
            depth: Int = 2,
            children: Int = 4,
            descendants: Int = 8,
            concurrentChildren: Int = 2
        ) {
            self.depth = depth
            self.children = children
            self.descendants = descendants
            self.concurrentChildren = concurrentChildren
        }

        public static let none = Self(
            depth: 0,
            children: 0,
            descendants: 0,
            concurrentChildren: 0
        )
    }

    public enum Reentry:
        Sendable,
        Codable,
        Hashable
    {
        case deny_ancestor_definition
        case allow_same_definition(
            maxOccurrences: Int
        )
    }

    public let enabled: Bool
    public let allowedAgents: AgentCapabilitySelection<AgentIdentifier>
    public let limits: Limits
    public let reentry: Reentry

    public init(
        enabled: Bool,
        allowedAgents: AgentCapabilitySelection<AgentIdentifier> = .none,
        limits: Limits = .none,
        reentry: Reentry = .deny_ancestor_definition
    ) {
        self.enabled = enabled
        self.allowedAgents = allowedAgents
        self.limits = limits
        self.reentry = reentry
    }

    public static let disabled = Self(
        enabled: false
    )

    public static func bounded(
        allowedAgents: AgentCapabilitySelection<AgentIdentifier>,
        limits: Limits = .init(),
        reentry: Reentry = .deny_ancestor_definition
    ) -> Self {
        .init(
            enabled: true,
            allowedAgents: allowedAgents,
            limits: limits,
            reentry: reentry
        )
    }
}
