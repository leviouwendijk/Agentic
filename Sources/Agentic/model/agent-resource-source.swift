import Macros
import Schema
/// Location of a resource's bytes.
@JSONSchema
public struct AgentResourceSource:
    Sendable,
    Codable,
    Hashable
{
    /// How `value` should be interpreted.
    public var kind: Kind
    /// A store reference or a URI, depending on `kind`.
    public var value: String

    public init(
        kind: Kind,
        value: String
    ) {
        self.kind = kind
        self.value = value
    }

    @JSONSchema
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
