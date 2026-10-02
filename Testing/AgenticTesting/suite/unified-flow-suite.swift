import Testing

enum UnifiedAgenticFlowSuite: TestFlowRegistry {
    static let title = "Agentic flow tests"

    static let flows: [TestFlow] =
        AgenticSmokeFlowSuite.flows
            + capabilitySelectionCompositionFlows
            + generatedDomainCatalogFlows
            + ModelRoutingFlowSuite.flows
            + AgenticInferenceFlowSuite.flows
            + ProgramsFlowSuite.flows
            + OptimizerFlowSuite.flows
            + InferenceAdapterFlowSuite.flows
            + RecoveryFlowSuite.flows
}
