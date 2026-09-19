public extension Recovery {
    enum EffectState:
        String,
        Sendable,
        Codable,
        Hashable
    {
        case none
        case not_applied
        case applied
        case unknown
    }
}
