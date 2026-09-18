import Primitives

public struct AgentIdentifier: StringIdentifier {
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }
}

public struct AgentDefinition:
    Definition,
    Codable,
    Hashable
{
    public let identifier: AgentIdentifier
    public let purpose: String
    public let instructions: String?

    public init(
        identifier: AgentIdentifier,
        purpose: String,
        instructions: String? = nil
    ) {
        self.identifier = identifier
        self.purpose = purpose
        self.instructions = instructions
    }
}

public protocol Agent: Sendable {
    static var definition: AgentDefinition { get }
}
