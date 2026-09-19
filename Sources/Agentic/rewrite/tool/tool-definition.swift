public struct ToolDefinition:
    Definition,
    Codable,
    Hashable,
    Identifiable
{
    public let identifier: ToolIdentifier
    public let purpose: String
    public let risk: ActionRisk

    public init(
        identifier: ToolIdentifier,
        purpose: String,
        risk: ActionRisk = .observe
    ) {
        self.identifier = identifier
        self.purpose = purpose
        self.risk = risk
    }

    public var id: ToolIdentifier {
        identifier
    }
}
