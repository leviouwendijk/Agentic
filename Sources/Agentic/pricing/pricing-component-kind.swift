public enum PricingComponentKind: String, Sendable, Codable, Hashable, CaseIterable {
    case inputTokens
    case outputTokens
    case cachedInputReadTokens
    case cachedInputWriteTokens
    case reasoningOutputTokens
    case request
    case fixed
    case other
}
