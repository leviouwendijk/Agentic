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

    public static func + (
        lhs: Self,
        rhs: Self
    ) -> Self {
        .init(
            domains: orderedUnique(
                lhs.domains + rhs.domains
            ),
            members: orderedUnique(
                lhs.members + rhs.members
            ),
            excluding: orderedUnique(
                lhs.excluding + rhs.excluding
            )
        )
    }
}

public extension AgentCapabilitySelection
where Identifier == ToolIdentifier {
    init(
        domains: [Namespace] = [],
        members: [any Tool.Type],
        excluding: [any Tool.Type] = []
    ) {
        self.init(
            domains: domains,
            members: members.map {
                $0.definition.identifier
            },
            excluding: excluding.map {
                $0.definition.identifier
            }
        )
    }

    init(
        domains: [any Domain.Type],
        members: [any Tool.Type] = [],
        excluding: [any Tool.Type] = []
    ) {
        self.init(
            domains: domains.map {
                $0.definition.namespace
            },
            members: members.map {
                $0.definition.identifier
            },
            excluding: excluding.map {
                $0.definition.identifier
            }
        )
    }
}

public extension AgentCapabilitySelection
where Identifier == ProgramIdentifier {
    init(
        domains: [Namespace] = [],
        members: [any Program.Type],
        excluding: [any Program.Type] = []
    ) {
        self.init(
            domains: domains,
            members: members.map {
                $0.definition.identifier
            },
            excluding: excluding.map {
                $0.definition.identifier
            }
        )
    }

    init(
        domains: [any Domain.Type],
        members: [any Program.Type] = [],
        excluding: [any Program.Type] = []
    ) {
        self.init(
            domains: domains.map {
                $0.definition.namespace
            },
            members: members.map {
                $0.definition.identifier
            },
            excluding: excluding.map {
                $0.definition.identifier
            }
        )
    }
}

public extension AgentCapabilitySelection
where Identifier == InferenceIdentifier {
    init(
        domains: [Namespace] = [],
        members: [any Inference.Type],
        excluding: [any Inference.Type] = []
    ) {
        self.init(
            domains: domains,
            members: members.map {
                $0.definition.identifier
            },
            excluding: excluding.map {
                $0.definition.identifier
            }
        )
    }

    init(
        domains: [any Domain.Type],
        members: [any Inference.Type] = [],
        excluding: [any Inference.Type] = []
    ) {
        self.init(
            domains: domains.map {
                $0.definition.namespace
            },
            members: members.map {
                $0.definition.identifier
            },
            excluding: excluding.map {
                $0.definition.identifier
            }
        )
    }
}

public extension AgentCapabilitySelection
where Identifier == AgentIdentifier {
    init(
        domains: [Namespace] = [],
        members: [any Agent.Type],
        excluding: [any Agent.Type] = []
    ) {
        self.init(
            domains: domains,
            members: members.map {
                $0.definition.identifier
            },
            excluding: excluding.map {
                $0.definition.identifier
            }
        )
    }

    init(
        domains: [any Domain.Type],
        members: [any Agent.Type] = [],
        excluding: [any Agent.Type] = []
    ) {
        self.init(
            domains: domains.map {
                $0.definition.namespace
            },
            members: members.map {
                $0.definition.identifier
            },
            excluding: excluding.map {
                $0.definition.identifier
            }
        )
    }
}

public struct AgentCapabilityScope:
    Sendable,
    Codable,
    Hashable
{
    public var tools: AgentCapabilitySelection<ToolIdentifier>
    public var programs: AgentCapabilitySelection<ProgramIdentifier>
    public var inferences: AgentCapabilitySelection<InferenceIdentifier>
    public var agents: AgentCapabilitySelection<AgentIdentifier>

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

    public static func + (
        lhs: Self,
        rhs: Self
    ) -> Self {
        .init(
            tools: lhs.tools + rhs.tools,
            programs: lhs.programs + rhs.programs,
            inferences: lhs.inferences + rhs.inferences,
            agents: lhs.agents + rhs.agents
        )
    }
}

public extension AgentCapabilityScope {
    init(
        domains: [any Domain.Type],
        tools: AgentCapabilitySelection<ToolIdentifier> = .none,
        programs: AgentCapabilitySelection<ProgramIdentifier> = .none,
        inferences: AgentCapabilitySelection<InferenceIdentifier> = .none,
        agents: AgentCapabilitySelection<AgentIdentifier> = .none
    ) {
        let namespaces = domains.map {
            $0.definition.namespace
        }

        self.init(
            tools:
                .init(domains: namespaces)
                + tools,
            programs:
                .init(domains: namespaces)
                + programs,
            inferences:
                .init(domains: namespaces)
                + inferences,
            agents:
                .init(domains: namespaces)
                + agents
        )
    }
}

public struct AgentCapabilities:
    Sendable,
    Codable,
    Hashable
{
    public var available: AgentCapabilityScope
    public var visible: AgentCapabilityScope
    /// What the runtime adds before the first request: all grants unless
    /// excluded here.
    public var grants: AgentCapabilityGrants

    public init(
        available: AgentCapabilityScope = .none,
        visible: AgentCapabilityScope = .none,
        grants: AgentCapabilityGrants = .standard
    ) {
        self.available = available
        self.visible = visible
        self.grants = grants
    }

    public static let none = Self()

    private enum CodingKeys: String, CodingKey {
        case available, visible, grants
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            available: try container.decode(AgentCapabilityScope.self, forKey: .available),
            visible: try container.decode(AgentCapabilityScope.self, forKey: .visible),
            grants: try container.decodeIfPresent(AgentCapabilityGrants.self, forKey: .grants) ?? .standard
        )
    }

    /// Exclusions combine: a grant either side excludes stays excluded.
    public static func + (
        lhs: Self,
        rhs: Self
    ) -> Self {
        .init(
            available:
                lhs.available
                + rhs.available,
            visible:
                lhs.visible
                + rhs.visible,
            grants: .init(
                excluding: lhs.grants.excluded + rhs.grants.excluded
            )
        )
    }
}

private func orderedUnique<Element: Hashable>(
    _ elements: [Element]
) -> [Element] {
    var seen: Set<Element> = []

    return elements.filter { element in
        seen.insert(element).inserted
    }
}
