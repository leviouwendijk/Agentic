import Primitives
import Schema

public struct AgentSkillDomain:
    StringIdentifier,
    JSONSchemaProviding
{
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public static var jsonschema: JSONSchema {
        .string()
    }
}

public extension AgentSkillDomain {
    static let core: Self = "core"
    static let swift: Self = "swift"
    static let web: Self = "web"
    static let writing: Self = "writing"
}
