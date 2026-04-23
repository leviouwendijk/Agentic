public enum AgentRole: String, Sendable, Codable, Hashable, CaseIterable {
    case system
    case user
    case assistant
    case tool
}
