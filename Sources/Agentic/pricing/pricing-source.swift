public enum PricingSource: String, Sendable, Codable, Hashable, CaseIterable {
    case bundled
    case imported
    case manual
    case live
    case unknown
}
