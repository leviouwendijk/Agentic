import Primitives

public struct AgentToolDefinition: Sendable, Codable, Hashable, Identifiable {
    public let identifier: AgentToolIdentifier
    public let description: String
    public let inputSchema: JSONValue?
    public let risk: ActionRisk

    public init(
        identifier: AgentToolIdentifier,
        description: String,
        inputSchema: JSONValue? = nil,
        risk: ActionRisk = .observe
    ) {
        self.identifier = identifier
        self.description = description
        self.inputSchema = inputSchema
        self.risk = risk
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
        inputSchema: JSONValue? = nil,
        risk: ActionRisk = .observe
    ) {
        self.init(
            identifier: .init(name),
            description: description,
            inputSchema: inputSchema,
            risk: risk
        )
    }
}
