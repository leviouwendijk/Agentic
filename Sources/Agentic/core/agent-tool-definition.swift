import Primitives

public struct AgentToolDefinition: Sendable, Codable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let description: String
    public let inputSchema: JSONValue?

    public init(
        id: String,
        name: String,
        description: String,
        inputSchema: JSONValue? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    }
}

public extension AgentToolDefinition {
    init(
        name: String,
        description: String,
        inputSchema: JSONValue? = nil
    ) {
        self.init(
            id: name,
            name: name,
            description: description,
            inputSchema: inputSchema
        )
    }
}
