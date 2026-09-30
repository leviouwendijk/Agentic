public enum InferenceKind:
    String,
    Sendable,
    Codable,
    Hashable,
    CaseIterable
{
    case generative
    case decision
}
