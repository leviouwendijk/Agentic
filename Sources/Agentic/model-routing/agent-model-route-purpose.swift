public enum AgentModelRoutePurpose: String, Sendable, Codable, Hashable, CaseIterable {
    case executor
    case planner
    case researcher
    case advisor
    case reviewer
    case summarizer
    case classifier
    case extractor
    case coder
    case local_private
}
