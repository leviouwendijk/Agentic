import Testing

enum InferenceAdapterFlowSuite: TestFlowRegistry {
    static let title = "Inference adapter flow tests"

    static let flows: [TestFlow] =
        InferenceAdapterSubstrateFlowTests.all
            + TypedInferenceAdapterFlowTests.all
            + NativeStructuredAdapterFlowTests.all
            + nativeStructuredAdapterRecoveryFlows
            + DecisionAuthoringFlowTests.all
}
