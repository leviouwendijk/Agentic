import Agentic
import AgenticModels
import Testing

enum ModelRoutingImplementationTesting {}

enum ModelRoutingImplementationTestSuite {
    static let testSuite = TestSuite(
        "model-routing-implementation",
        title: "Agentic model routing implementation tests"
    ) {
        diagnosticTest(
            "routing-boundaries",
            tags: [
                "model-routing",
                "routing",
                "configuration",
            ]
        ) {
            try await ModelRoutingImplementationTesting
                .runRoutingBoundaries()
        }

        diagnosticTest(
            "broker-model-invocation",
            tags: [
                "model-routing",
                "broker",
                "invocation",
                "routing",
                "ledger",
            ]
        ) {
            try await ModelRoutingImplementationTesting
                .runBrokerModelInvocation()
        }

        diagnosticTest(
            "selection-resolution",
            tags: [
                "model-routing",
                "selection",
                "resolution",
            ]
        ) {
            try await ModelRoutingImplementationTesting
                .runSelectionResolution()
        }

        diagnosticTest(
            "preference-fallback",
            tags: [
                "model-routing",
                "routing",
                "preferences",
                "constraints",
            ]
        ) {
            try await ModelRoutingImplementationTesting
                .runPreferenceFallback()
        }

        diagnosticTest(
            "multiple-gateway-resolution",
            tags: [
                "model-routing",
                "routing",
                "gateway",
                "multiple-gateways",
            ]
        ) {
            try await ModelRoutingImplementationTesting
                .runMultipleGatewayResolution()
        }

        diagnosticTest(
            "gateway-availability-catalog",
            tags: [
                "model-routing",
                "gateway",
                "availability",
                "catalog",
            ]
        ) {
            try await ModelRoutingImplementationTesting
                .runGatewayAvailabilityCatalog()
        }

        diagnosticTest(
            "gateway-aware-routing",
            tags: [
                "model-routing",
                "routing",
                "gateway",
                "availability",
                "preferences",
                "constraints",
            ]
        ) {
            try await ModelRoutingImplementationTesting
                .runGatewayAwareRouting()
        }

        Test(
            "exact-model-selection-is-fail-closed",
            tags: [
                "model-routing",
                "selection",
                "model",
                "constraints",
            ]
        ) {
            let modelID: AgentModelID = "fixture:exact-model"
            let gateway: AgentModelGatewayIdentifier = "fixture.gateway"
            let selection = AgentModelSelection.exactModel(
                modelID,
                through: gateway
            )

            try Expect.equal(
                selection.preferences.preferredModelID,
                modelID,
                "exact model selection prefers the requested model"
            )
            try Expect.equal(
                selection.preferences.gateway,
                gateway,
                "exact model selection prefers the requested gateway"
            )
            try Expect.equal(
                selection.constraints.allowedModelIDs,
                Set([modelID]),
                "exact model selection constrains routing to the requested model"
            )
            try Expect.equal(
                selection.constraints.allowedGatewayIdentifiers,
                Set([gateway]),
                "exact model selection constrains routing to the requested gateway"
            )
        }

        Test(
            "known-models-addon"
        ) {
            try Expect.equal(
                KnownModel.glm.v5_3_flash.rawValue,
                "zai:glm-5-3-flash",
                "AgenticModels exposes canonical known model identifiers"
            )
        }
    }

    private static func diagnosticTest(
        _ id: String,
        tags: Set<String>,
        operation: @escaping @Sendable () async throws -> [TestDiagnostic]
    ) -> Test {
        Test(
            id,
            tags: tags
        ) { context in
            await context.record(
                contentsOf: try await operation()
            )
        }
    }
}
