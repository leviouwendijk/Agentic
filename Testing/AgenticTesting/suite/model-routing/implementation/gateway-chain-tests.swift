import Agentic
import Foundation
import Testing

extension ModelRoutingImplementationTesting {
    static func runGatewayChain()
        async throws
        -> [TestDiagnostic]
    {
        let modelID = AgentModelID(rawValue: "fixture:shared-model")
        let first = AgentModelGatewayIdentifier("fixture.gateway.first")
        let second = AgentModelGatewayIdentifier("fixture.gateway.second")
        let third = AgentModelGatewayIdentifier("fixture.gateway.third")

        // The cheapest profile sits on the last gateway, so only chain
        // order can make the second gateway win.
        let onSecond = AgentModelProfile(
            identifier: "fixture.profile.second",
            gatewayIdentifier: second,
            model: "shared-model",
            modelID: modelID,
            cost: .premium
        )
        let onThird = AgentModelProfile(
            identifier: "fixture.profile.third",
            gatewayIdentifier: third,
            model: "shared-model",
            modelID: modelID,
            cost: .cheap
        )
        let catalog = try ProfileCatalog(
            profiles: [
                onSecond,
                onThird,
            ]
        )
        let router = StaticModelRouter()

        let byModel = try router.route(
            .init(
                selection: .init(
                    purpose: .executor,
                    preferences: .init(
                        preferredModelID: modelID,
                        gateway: first,
                        gateways: [second, third]
                    )
                )
            ),
            catalog: catalog
        )
        try Expect.equal(
            byModel.route.profile.identifier,
            onSecond.identifier,
            "a preferred model routes through the earliest chain gateway that serves it"
        )

        let byGateway = try router.route(
            .init(
                selection: .init(
                    purpose: .executor,
                    preferences: .init(
                        gateways: [first, third, second]
                    )
                )
            ),
            catalog: catalog
        )
        try Expect.equal(
            byGateway.route.profile.identifier,
            onThird.identifier,
            "without a model, the first available chain gateway wins"
        )
        try Expect.true(
            byGateway.diagnostics.contains { (diagnostic: AgentModelSelectionDiagnostic) in
                diagnostic.code == .preference_unavailable
                    && diagnostic.metadata["gateway"] == first.rawValue
            },
            "skipped chain gateways are observable"
        )

        let missingModel = AgentModelID(rawValue: "fixture:missing-model")
        var refused = false
        do {
            _ = try router.route(
                .init(selection: .init(
                    purpose: .executor,
                    preferences: .init(preferredModelID: missingModel)
                )),
                catalog: catalog
            )
        } catch AgentModelRoutingError.selectionRefused(let diagnostics) {
            refused = diagnostics.contains { $0.code == .preference_unavailable }
        }
        try Expect.true(refused, "an unavailable explicit model refuses substitution by default")

        let fallback = try router.route(
            .init(selection: .init(
                purpose: .executor,
                preferences: .init(preferredModelID: missingModel, allowsFallback: true)
            )),
            catalog: catalog
        )
        try Expect.true(
            fallback.diagnostics.contains { $0.code == .fallback_selected },
            "explicitly allowed substitution reports fallback"
        )

        let overridden = AgentModelPreferences(
            gateway: first,
            gateways: [second]
        ).overriding(
            with: .init(gateways: [third])
        )
        try Expect.equal(
            overridden.gatewayChain,
            [third],
            "a higher-priority chain replaces the whole lower-priority target"
        )

        let legacy = try JSONDecoder().decode(
            AgentModelPreferences.self,
            from: Data(#"{"gateway":"fixture.gateway.first"}"#.utf8)
        )
        try Expect.equal(
            legacy.gatewayChain,
            [first],
            "preferences encoded before gateway chains still decode"
        )

        try Expect.true(!legacy.allowsFallback, "legacy explicit selections default to refusal")

        return [
            .field(
                "chain_selected",
                byModel.route.profile.identifier.rawValue
            ),
        ]
    }
}
