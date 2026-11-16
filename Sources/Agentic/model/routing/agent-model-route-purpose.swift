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

public extension AgentModelRoutePurpose {
    /// What a general model serves: every role but on-device private work.
    /// Specialized models (classifiers, small local models) narrow this.
    static let general: Set<Self> = Set(allCases).subtracting([.local_private])
}
