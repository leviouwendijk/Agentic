public extension Recovery {
    enum RetrySafety:
        String,
        Sendable,
        Codable,
        Hashable
    {
        case safe
        case requires_reconciliation
        case unsafe
    }
}
