import Testing

enum UnifiedAgenticTestSuite {
    static let testSuite = TestSuite(
        "agentic",
        title: "Agentic tests"
    ) {
        AgenticSmokeFlowSuite.testSuite
        capabilitySelectionCompositionFlows.map {
            TestNode.test(
                Test($0)
            )
        }
        domainCatalogFlows.map {
            TestNode.test(
                Test($0)
            )
        }
        linkerDomainCatalogFlows.map {
            TestNode.test(
                Test($0)
            )
        }
        ModelRoutingFlowSuite.testSuite
        AgenticInferenceFlowSuite.testSuite
        ProgramsFlowSuite.testSuite
        OptimizerFlowSuite.testSuite
        InferenceAdapterFlowSuite.testSuite
        RecoveryFlowSuite.testSuite
        HarnessTestSuite.testSuite
        ExecutionTestSuite.testSuite
    }
}
