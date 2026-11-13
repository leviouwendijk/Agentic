public struct AgentResourceSource:
    Sendable,
    Codable,
    Hashable
{
    public var kind: Kind
    public var value: String

    public init(
        kind: Kind,
        value: String
    ) {
        self.kind = kind
        self.value = value
    }

    public enum Kind:
        String,
        Sendable,
        Codable,
        Hashable,
        CaseIterable
    {
        case reference
        case uri
    }
}
