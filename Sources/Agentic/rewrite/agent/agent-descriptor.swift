import Primitives

public struct AgentDescriptor:
    Sendable,
    Codable,
    Hashable,
    Identifiable
{
    public let identifier: AgentIdentifier
    public let description: String
    public let inputSchema: JSONValue
    public let outputSchema: JSONValue

    public init(
        identifier: AgentIdentifier,
        description: String,
        inputSchema: JSONValue,
        outputSchema: JSONValue
    ) {
        self.identifier = identifier
        self.description = description
        self.inputSchema = inputSchema
        self.outputSchema = outputSchema
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
            inputSchema: Input.jsonschema.jsonvalue,
            outputSchema: Output.jsonschema.jsonvalue
        )
    }
}
