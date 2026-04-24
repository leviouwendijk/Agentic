public enum AgentSessionStatus: String, Sendable, Codable, Hashable, CaseIterable {
    case active
    case awaiting_approval
    case completed
    case archived
}
