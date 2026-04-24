import TestFlows

@main
struct AgenticFlowTesting {
    static func main() async {
        await TestFlowCLI.run(
            suite: AgenticFlowSuite.self
        )
    }
}
