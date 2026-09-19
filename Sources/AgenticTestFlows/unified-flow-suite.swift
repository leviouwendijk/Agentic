import TestFlows

enum UnifiedAgenticFlowSuite: TestFlowRegistry {
    static let title = "Agentic flow tests"

    static let flows: [TestFlow] =
        AgenticSmokeFlowSuite.flows
            + AgenticInferenceFlowSuite.flows
            + ProgramsFlowSuite.flows
            + OptimizerFlowSuite.flows
            + InferenceAdapterFlowSuite.flows
}
