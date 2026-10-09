import Primitives

public struct ToolDescriptor:
    Sendable,
    Codable,
    Hashable,
    Identifiable
{
    public let identifier: ToolIdentifier
    public let description: String
    public let input: JSONValue?
    public let risk: ActionRisk

    public init(
        identifier: ToolIdentifier,
        description: String,
        input: JSONValue? = nil,
        risk: ActionRisk = .observe
    ) {
        self.identifier = identifier
        self.description = description
        self.input = input
        self.risk = risk
    }

    private enum CodingKeys: String, CodingKey {
        case identifier, description, risk
        case input = "inputSchema"
    }
}

public extension ToolDescriptor {
    var id: ToolIdentifier {
        identifier
    }

    var name: String {
        identifier.rawValue
    }

    /// Strip Tool-only governance metadata at the model transport boundary.
    var modelFunction: ModelFunctionDescriptor {
        .init(
            name: name,
            description: description,
            input: input
        )
    }

    init(
        name: String,
        description: String,
        input: JSONValue? = nil,
        risk: ActionRisk = .observe
    ) {
        self.init(
            identifier: .init(name),
            description: description,
            input: input,
            risk: risk
        )
    }

}
