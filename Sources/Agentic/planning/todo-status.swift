public enum TodoStatus: String, Sendable, Codable, Hashable, CaseIterable {
    case pending
    // case inProgress = "in_progress"
    case processing
    case completed
}
