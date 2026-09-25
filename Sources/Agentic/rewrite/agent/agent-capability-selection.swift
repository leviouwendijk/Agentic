public struct AgentCapabilitySelection<Identifier>:
    Sendable,
    Codable,
    Hashable
where
    Identifier: Sendable,
    Identifier: Codable,
    Identifier: Hashable
{
    public let domains: [Namespace]
    public let members: [Identifier]
    public let excluding: [Identifier]

    public init(
        domains: [Namespace] = [],
        members: [Identifier] = [],
        excluding: [Identifier] = []
    ) {
        self.domains = domains
        self.members = members
        self.excluding = excluding
    }

    public static var none: Self {
        .init()
    }
}

public struct AgentCapabilities:
    Sendable,
    Codable,
    Hashable
{
    public let tools: AgentCapabilitySelection<ToolIdentifier>
    public let programs: AgentCapabilitySelection<ProgramIdentifier>
    public let inferences: AgentCapabilitySelection<InferenceIdentifier>
    public let agents: AgentCapabilitySelection<AgentIdentifier>

    public init(
        tools: AgentCapabilitySelection<ToolIdentifier> = .none,
        programs: AgentCapabilitySelection<ProgramIdentifier> = .none,
        inferences: AgentCapabilitySelection<InferenceIdentifier> = .none,
        agents: AgentCapabilitySelection<AgentIdentifier> = .none
    ) {
        self.tools = tools
        self.programs = programs
        self.inferences = inferences
        self.agents = agents
    }

    public static let none = Self()
}
