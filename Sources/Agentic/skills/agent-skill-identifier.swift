import Primitives

public struct AgentSkillIdentifier:
    StringIdentifier
{
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }
}
