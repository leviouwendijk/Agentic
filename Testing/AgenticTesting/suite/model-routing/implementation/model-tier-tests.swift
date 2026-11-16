import Agentic
import AgenticModels
import Testing

extension ModelRoutingImplementationTesting {
    /// Tiers are what a model can be relied on for; a requirement names the
    /// least it accepts, per agent. Roles are general unless narrowed.
    static func runModelTiers() async throws -> [TestDiagnostic] {
        let frontier = AgentModelProfile(
            known: KnownModel.claude.opus_5_5,
            identifier: "tier.opus",
            gatewayIdentifier: "fixture.gateway",
            model: "opus"
        )
        let standard = AgentModelProfile(
            known: KnownModel.claude.haiku_5_5,
            identifier: "tier.haiku",
            gatewayIdentifier: "fixture.gateway",
            model: "haiku"
        )
        let unjudged = AgentModelProfile(
            identifier: "tier.unknown",
            gatewayIdentifier: "fixture.gateway",
            model: "unknown"
        )
        try Expect.equal(frontier.tier, .frontier, "facts give the tier")
        try Expect.equal(frontier.limits.inputTokens, 1_000_000, "facts give documented limits")
        try Expect.equal(standard.cost, .cheap, "facts give the cost class")
        try Expect.true(
            unjudged.purposes == AgentModelRoutePurpose.general && unjudged.supports(.init(purpose: .planner)),
            "a model serves every role unless narrowed"
        )
        try Expect.true(!unjudged.purposes.contains(.local_private), "but not on-device private work")

        func selection(_ minimum: AgentModelTier?) -> AgentModelSelection {
            .init(purpose: .planner, requirements: .init(minimumTier: minimum))
        }
        try Expect.true(frontier.supports(selection(.strong)), "frontier satisfies at least strong")
        try Expect.true(!standard.supports(selection(.strong)), "standard does not")
        try Expect.true(standard.supports(selection(.standard)), "the same model suits an agent asking less")
        try Expect.true(!unjudged.supports(selection(.light)), "an unjudged model is not assumed to qualify")
        try Expect.equal(
            AgentModelRequirements(minimumTier: .standard).merging(.init(minimumTier: .strong)).minimumTier,
            .strong,
            "merged requirements keep the stricter tier"
        )

        let catalog = try ProfileCatalog(profiles: [frontier, standard])
        let routed = try StaticModelRouter().route(.init(selection: selection(.strong)), catalog: catalog)
        try Expect.equal(routed.route.profile.identifier, frontier.identifier, "routing honours the tier")
        return []
    }
}
