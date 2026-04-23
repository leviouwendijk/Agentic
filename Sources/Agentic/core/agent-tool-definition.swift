import Primitives

public struct AgentToolDefinition: Sendable, Codable, Hashable, Identifiable {
    public let identifier: AgentToolIdentifier
    public let description: String
    public let inputSchema: JSONValue?

    public init(
        identifier: AgentToolIdentifier,
        description: String,
        inputSchema: JSONValue? = nil
    ) {
        self.identifier = identifier
        self.description = description
        self.inputSchema = inputSchema
    }
}

public extension AgentToolDefinition {
    var id: AgentToolIdentifier {
        identifier
    }

    var name: String {
        identifier.rawValue
    }

    init(
        name: String,
        description: String,
        inputSchema: JSONValue? = nil
    ) {
        self.init(
            identifier: .init(name),
            description: description,
            inputSchema: inputSchema
        )
    }
}
