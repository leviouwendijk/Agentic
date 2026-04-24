import Tokens

public struct AgentCostProjection: Sendable, Codable, Hashable {
    public var status: AgentCostProjectionStatus
    public var confidence: AgentCostProjectionConfidence
    public var pricing: ModelPricingSnapshot?
    public var usage: AgentCostUsage
    public var tokenEstimate: TokenEstimate?
    public var amount: AgentCostAmount?
    public var lineItems: [AgentCostLineItem]
    public var issues: [AgentCostProjectionIssue]
    public var metadata: [String: String]

    public init(
        status: AgentCostProjectionStatus,
        confidence: AgentCostProjectionConfidence,
        pricing: ModelPricingSnapshot? = nil,
        usage: AgentCostUsage,
        tokenEstimate: TokenEstimate? = nil,
        amount: AgentCostAmount? = nil,
        lineItems: [AgentCostLineItem] = [],
        issues: [AgentCostProjectionIssue] = [],
        metadata: [String: String] = [:]
    ) {
        self.status = status
        self.confidence = confidence
        self.pricing = pricing
        self.usage = usage
        self.tokenEstimate = tokenEstimate
        self.amount = amount
        self.lineItems = lineItems
        self.issues = issues
        self.metadata = metadata
    }

    public var isAvailable: Bool {
        status == .available || status == .partial
    }
}
