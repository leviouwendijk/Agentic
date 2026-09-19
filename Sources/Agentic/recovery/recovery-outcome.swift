public extension Recovery {
    enum Outcome:
        String,
        Sendable,
        Codable,
        Hashable
    {
        case recovered
        case failed
        case propagated
        case suspended
        case aborted
        case exhausted
    }
}
