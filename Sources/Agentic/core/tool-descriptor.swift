import Primitives

public struct ToolDescriptor:
    Sendable,
    Codable,
    Hashable,
    Identifiable
{
    public let identifier: ToolIdentifier
    public let description: String
    public let inputSchema: JSONValue?
    public let risk: ActionRisk

    public init(
        identifier: ToolIdentifier,
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

public extension ToolDescriptor {
    var id: ToolIdentifier {
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
