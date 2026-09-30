import Agentic
import Testing

enum ModelRoutingFlowSuite: TestFlowRegistry {
    static let title = "Agentic model routing flow tests"

    static let flows: [TestFlow] = [
        TestFlow(
            "model-kind-selection",
            tags: [
                "model-routing",
                "model-kind",
            ]
        ) {
            try modelKindDiagnostics()
        },
    ]

    private static func modelKindDiagnostics() throws -> [TestDiagnostic] {
        let generative = AgentModelProfile(
            identifier: "fixture.generative",
            gatewayIdentifier: "fixture.gateway",
            model: "fixture-generative"
        )
        let decision = AgentModelProfile(
            identifier: "fixture.decision",
            gatewayIdentifier: "fixture.gateway",
            model: "fixture-decision",
            kind: .decision
        )

        let defaultSelection = AgentModelSelection(
            purpose: .executor
        )
        let decisionSelection = AgentModelSelection(
            purpose: .executor,
            kind: .decision
        )

        try Expect.equal(
            generative.kind,
            .generative,
            "model profiles default to generative"
        )
        try Expect.equal(
            defaultSelection.kind,
            .generative,
            "model selections default to generative"
        )
        try Expect.equal(
            generative.supports(defaultSelection),
            true,
            "generative profile supports the default generative selection"
        )
        try Expect.equal(
            decision.supports(defaultSelection),
            false,
            "decision profile does not satisfy a generative selection"
        )
        try Expect.equal(
            decision.supports(decisionSelection),
            true,
            "decision profile supports an explicit decision selection"
        )
        try Expect.equal(
            generative.supports(decisionSelection),
            false,
            "generative profile does not satisfy a decision selection"
        )

        return [
            .field(
                "default_kind",
                defaultSelection.kind.rawValue
            ),
            .field(
                "decision_kind",
                decisionSelection.kind.rawValue
            ),
            .field(
                "generative_accepts_decision",
                String(
                    generative.supports(
                        decisionSelection
                    )
                )
            ),
            .field(
                "decision_accepts_decision",
                String(
                    decision.supports(
                        decisionSelection
                    )
                )
            ),
        ]
    }
}
