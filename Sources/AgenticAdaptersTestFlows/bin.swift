import TestFlows

@main
enum InferenceAdapterFlowTestMain {
    static func main() async {
        await TestFlowCLI.run(
            suite: InferenceAdapterFlowSuite.self
        )
    }
}
