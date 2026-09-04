import Schema

public struct PreparedIntentIdentifier:
    Sendable,
    Codable,
    Hashable,
    RawRepresentable,
    ExpressibleByStringLiteral,
    CustomStringConvertible,
    JSONSchemaProviding
{
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public init(
        _ rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public init(
        stringLiteral value: StringLiteralType
    ) {
        self.rawValue = value
    }

    public var description: String {
        rawValue
    }

    public static var jsonschema: JSONSchema {
        .string()
    }
}
