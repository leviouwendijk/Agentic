import Primitives

public struct AgentDescriptor:
    Sendable,
    Codable,
    Hashable,
    Identifiable
{
    public let identifier: AgentIdentifier
    public let description: String
    public let input: JSONValue
    public let output: JSONValue

    public init(
        identifier: AgentIdentifier,
        description: String,
        input: JSONValue,
        output: JSONValue
    ) {
        self.identifier = identifier
        self.description = description
        self.input = input
        self.output = output
    }

    private enum CodingKeys: String, CodingKey {
        case identifier, description
        case input = "inputSchema"
        case output = "outputSchema"
    }

    public var id: AgentIdentifier {
        identifier
    }
}

public extension Agent {
    static var descriptor: AgentDescriptor {
        .init(
            identifier: definition.identifier,
            description: definition.purpose,
            input: contract.input.jsonvalue,
            output: contract.output.jsonvalue
        )
    }
}

