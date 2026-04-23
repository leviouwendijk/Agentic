public enum AutonomyMode: String, Sendable, Codable, Hashable, CaseIterable {
    case suggest_only 
    case auto_observe 
    case auto_bounded_mutate 
    case review_privileged 
}
