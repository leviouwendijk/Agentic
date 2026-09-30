public enum AgentModelKind:
    String,
    Sendable,
    Codable,
    Hashable,
    CaseIterable
{
    case generative
    case decision
}
