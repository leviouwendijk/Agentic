import Testing

enum InferenceAdapterFlowSuite: TestFlowRegistry {
    static let title = "Inference adapter flow tests"

    static let flows: [TestFlow] =
        InferenceAdapterSubstrateFlowTests.all
            + NativeStructuredAdapterFlowTests.all
            + nativeStructuredAdapterRecoveryFlows
}
