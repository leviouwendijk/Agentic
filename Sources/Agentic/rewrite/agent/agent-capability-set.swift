/// Concrete, deterministically ordered capability identifiers.
///
/// This value is a resolved semantic selection, not evidence that the referenced
/// capabilities are installed or executable. Runtime authority must intersect it
/// with the installed universe before use.
public struct AgentCapabilitySet:
    Sendable,
    Codable,
    Hashable
{
    public let tools: [ToolIdentifier]
    public let programs: [ProgramIdentifier]
    public let inferences: [InferenceIdentifier]
    public let agents: [AgentIdentifier]

    public init(
        tools: [ToolIdentifier] = [],
        programs: [ProgramIdentifier] = [],
        inferences: [InferenceIdentifier] = [],
        agents: [AgentIdentifier] = []
    ) {
        self.tools = orderedUniqueCapabilities(
            tools
        )
        self.programs = orderedUniqueCapabilities(
            programs
        )
        self.inferences = orderedUniqueCapabilities(
            inferences
        )
        self.agents = orderedUniqueCapabilities(
            agents
        )
    }

    public static let none = Self()
}

private func orderedUniqueCapabilities<
    Identifier: Hashable
>(
    _ identifiers: [Identifier]
) -> [Identifier] {
    var seen: Set<Identifier> = []

    return identifiers.filter { identifier in
        seen.insert(identifier).inserted
    }
}
