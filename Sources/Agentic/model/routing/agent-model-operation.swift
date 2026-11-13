public enum AgentModelOperation:
    String,
    Sendable,
    Codable,
    Hashable,
    CaseIterable
{
    case generation
    case decision
    case extraction
    case summarization
    case compression
}
