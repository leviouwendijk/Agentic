import Agentic

/// What is true of a model wherever it is served: one source, so every
/// gateway serving it (native, Bedrock, a router) describes it the same way.
/// Capabilities are not here: a gateway can lack a feature the model has.
public struct AgentModelFacts: Sendable, Hashable {
    public var tier: AgentModelTier?
    public var limits: AgentModelLimits
    public var cost: AgentModelCostClass?
    public var latency: AgentModelLatencyClass?

    public init(
        tier: AgentModelTier? = nil,
        limits: AgentModelLimits = .unknown,
        cost: AgentModelCostClass? = nil,
        latency: AgentModelLatencyClass? = nil
    ) {
        self.tier = tier
        self.limits = limits
        self.cost = cost
        self.latency = latency
    }
}

public extension KnownModel {
    /// The facts recorded for a model; nil when none are.
    ///
    /// Limits come from provider documentation and are left unknown where
    /// none is published. Tiers are declared judgements, to be adjusted as
    /// measurements arrive; costs are classes of list price.
    static func facts(
        _ model: AgentModelID
    ) -> AgentModelFacts? {
        table[model]
    }

    private static let table: [AgentModelID: AgentModelFacts] = {
        // Anthropic documentation: 1M input and 128K output on these models.
        let million = AgentModelLimits(inputTokens: 1_000_000, outputTokens: 128_000)
        return [
            claude.fable_5_2: .init(tier: .frontier, cost: .premium, latency: .high),
            claude.fable_5: .init(tier: .frontier, limits: million, cost: .premium, latency: .high),
            claude.opus_5_5: .init(tier: .frontier, limits: million, cost: .expensive, latency: .medium),
            claude.opus_5: .init(tier: .frontier, limits: million, cost: .expensive, latency: .medium),
            claude.opus_4_8: .init(tier: .strong, limits: million, cost: .expensive, latency: .medium),
            claude.opus_4_7: .init(tier: .strong, limits: million, cost: .expensive, latency: .medium),
            claude.opus_4_6: .init(tier: .strong, limits: million, cost: .expensive, latency: .medium),
            claude.sonnet_5_5: .init(tier: .strong, limits: million, cost: .balanced, latency: .medium),
            claude.sonnet_5: .init(tier: .strong, limits: million, cost: .balanced, latency: .medium),
            claude.sonnet_4_6: .init(tier: .strong, limits: million, cost: .balanced, latency: .medium),
            claude.haiku_5_5: .init(tier: .standard, limits: million, cost: .cheap, latency: .low),
            claude.haiku_4_5: .init(
                tier: .standard,
                limits: .init(inputTokens: 200_000),
                cost: .cheap,
                latency: .low
            ),

            deepseek.v4_pro: .init(tier: .strong),
            deepseek.v4_pro_0813: .init(tier: .strong),
            deepseek.v4_flash: .init(tier: .standard),
            deepseek.v4_1_flash: .init(tier: .standard),
            deepseek.v4_1_flash_1017: .init(tier: .standard),

            foundation_models: .init(tier: .light, cost: .free, latency: .low),
        ]
    }()
}

public extension AgentModelProfile {
    /// A profile for a known model: tier, limits, cost and latency come from
    /// `KnownModel.facts`, unless given here for this gateway.
    init(
        known modelID: AgentModelID,
        identifier: AgentModelProfileIdentifier,
        gatewayIdentifier: AgentModelGatewayIdentifier,
        model: String,
        title: String? = nil,
        purposes: Set<AgentModelRoutePurpose> = AgentModelRoutePurpose.general,
        capabilities: Set<AgentModelCapability> = [.text],
        cost: AgentModelCostClass? = nil,
        latency: AgentModelLatencyClass? = nil,
        privacy: AgentModelPrivacyClass = .private_cloud,
        limits: AgentModelLimits? = nil,
        metadata: [String: String] = [:]
    ) {
        let facts = KnownModel.facts(modelID) ?? .init()
        self.init(
            identifier: identifier,
            gatewayIdentifier: gatewayIdentifier,
            model: model,
            modelID: modelID,
            title: title,
            purposes: purposes,
            capabilities: capabilities,
            tier: facts.tier,
            cost: cost ?? facts.cost ?? .balanced,
            latency: latency ?? facts.latency ?? .medium,
            privacy: privacy,
            limits: limits ?? facts.limits,
            metadata: metadata
        )
    }
}
