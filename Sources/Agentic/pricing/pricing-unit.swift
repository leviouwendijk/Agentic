public enum PricingUnit: String, Sendable, Codable, Hashable, CaseIterable {
    case perMillionTokens
    case perRequest
    case fixed
}
