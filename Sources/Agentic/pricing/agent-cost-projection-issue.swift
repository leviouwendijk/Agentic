public enum AgentCostProjectionIssueKind: String, Sendable, Codable, Hashable, CaseIterable {
    case missingPricingComponent
    case missingUsage
    case zeroUsage
    case currencyMismatch
    case pricingUnavailable
}

public struct AgentCostProjectionIssue: Sendable, Codable, Hashable {
    public var kind: AgentCostProjectionIssueKind
    public var message: String
    public var componentKind: PricingComponentKind?

    public init(
        kind: AgentCostProjectionIssueKind,
        message: String,
        componentKind: PricingComponentKind? = nil
    ) {
        self.kind = kind
        self.message = message
        self.componentKind = componentKind
    }
}
