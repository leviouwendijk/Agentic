public extension Recovery {
    enum Stage:
        String,
        Sendable,
        Codable,
        Hashable
    {
        case preparation
        case routing
        case execution
        case decoding
        case validation
        case reconciliation
    }
}
