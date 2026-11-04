import Agentic
import Testing

enum ModelRoutingFlowSuite: TestFlowRegistry {
    static let title = "Agentic model routing flow tests"

    static let flows: [TestFlow] = [
        TestFlow(
            "model-operation-selection",
            tags: ["model-routing", "model-operation"]
        ) {
            try modelOperationDiagnostics()
        },
        TestFlow(
            "model-operation-composition",
            tags: ["model-routing", "model-operation"]
        ) {
            try modelOperationCompositionDiagnostics()
        },
        TestFlow(
            "model-selection-precedence",
            tags: ["model-routing", "precedence"]
        ) {
            try modelSelectionPrecedenceDiagnostics()
        },
    ]

    private static func modelSelectionPrecedenceDiagnostics() throws -> [TestDiagnostic] {
        let application = AgentModelSelection(
            purpose: .executor,
            preferences: .init(preferredModelID: "application.model", gateway: "application.gateway")
        )
        let agent = AgentModelSelection(
            purpose: .executor,
            preferences: .init(preferredProfileIdentifier: "agent.profile")
        )
        let contributions: [ModelSelectionResolver.Contribution] = [
            .init(source: .agent, selection: agent),
            .init(source: .application_default, selection: application)
        ]
        let normal = try ModelSelectionResolver().resolve(contributions).selection
        try Expect.equal(normal.preferences.preferredProfileIdentifier, AgentModelProfileIdentifier("agent.profile"), "agent wins by default")
        try Expect.equal(normal.preferences.preferredModelID, nil, "lower-priority model identifier cleared")
        try Expect.equal(normal.preferences.gateway, nil, "lower-priority gateway cleared")

        var reversed = ModelSelectionPrecedence.default.sources
        guard let agentPosition = reversed.firstIndex(of: .agent),
              let applicationPosition = reversed.firstIndex(of: .application_default)
        else {
            throw ModelSelectionPrecedence.Failure.incomplete_or_duplicate_sources
        }
        reversed.swapAt(agentPosition, applicationPosition)
        let custom = try ModelSelectionPrecedence(sources: reversed)
        let changed = try ModelSelectionResolver(precedence: custom).resolve(contributions).selection
        try Expect.equal(changed.preferences.preferredModelID, AgentModelID("application.model"), "custom ordering changes winner")
        try Expect.equal(changed.preferences.preferredProfileIdentifier, nil, "application model clears agent profile")
        return [.field("winner", changed.preferences.preferredModelID?.rawValue ?? "missing")]
    }

    private static func modelOperationDiagnostics() throws -> [TestDiagnostic] {
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
        let hybrid = AgentModelProfile(
            identifier: "fixture.hybrid",
            gatewayIdentifier: "fixture.gateway",
            model: "fixture-hybrid",
            operations: [.generation, .decision]
        )
        let extraction = AgentModelProfile(
            identifier: "fixture.extractor",
            gatewayIdentifier: "fixture.gateway",
            model: "fixture-extractor",
            operations: [.extraction]
        )
        let defaultSelection = AgentModelSelection(purpose: .executor)
        let decisionSelection = AgentModelSelection(
            purpose: .executor,
            operation: .decision
        )
        let extractionSelection = AgentModelSelection(
            purpose: .executor,
            operation: .extraction
        )

        try Expect.equal(defaultSelection.operation, .generation, "default operation")
        try Expect.equal(generative.supports(defaultSelection), true, "generative eligible")
        try Expect.equal(decision.supports(defaultSelection), false, "decision-only excluded")
        try Expect.equal(decision.supports(decisionSelection), true, "decision eligible")
        try Expect.equal(generative.supports(decisionSelection), false, "generation-only excluded")
        try Expect.equal(hybrid.supports(decisionSelection), true, "hybrid supports decisions")
        try Expect.equal(hybrid.kind, .generative, "operation does not alter model family")
        try Expect.equal(extraction.supports(extractionSelection), true, "extraction eligible")
        try Expect.equal(extraction.supports(defaultSelection), false, "extraction-only excluded")

        return [
            .field("default_operation", defaultSelection.operation.rawValue),
            .field("decision_operation", decisionSelection.operation.rawValue),
            .field("extraction_operation", extractionSelection.operation.rawValue),
        ]
    }

    private static func modelOperationCompositionDiagnostics() throws -> [TestDiagnostic] {
        let resolver = ModelSelectionResolver()
        let decisionSelection = AgentModelSelection(
            purpose: .executor,
            operation: .decision
        )
        let result = try resolver.resolve([
            .init(source: .mode_default, selection: decisionSelection),
            .init(source: .user, selection: decisionSelection),
        ])
        try Expect.equal(result.selection.operation, .decision, "operation preserved")

        let overridden = try resolver.resolve([
            .init(source: .user, selection: decisionSelection),
            .init(source: .mode_default, selection: .init(purpose: .executor)),
        ])
        try Expect.equal(
            overridden.selection.operation,
            .decision,
            "user operation overrides mode default regardless of insertion order"
        )

        return [.field("resolved_operation", result.selection.operation.rawValue)]
    }
}
