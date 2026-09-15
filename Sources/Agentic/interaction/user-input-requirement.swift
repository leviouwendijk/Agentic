public enum UserInputRequirement:
    String,
    Sendable,
    Codable,
    Hashable,
    CaseIterable
{
    case required
    case optional
}
