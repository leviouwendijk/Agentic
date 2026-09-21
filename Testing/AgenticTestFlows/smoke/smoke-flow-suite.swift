import AgenticTesting
import TestFlows

enum AgenticSmokeFlowSuite: TestFlowRegistry {
    static let title = "Agentic smoke flow tests"

    static let flows: [TestFlow] = [
        TestFlow(
            "semantic-authoring-macros",
            tags: [
                "agentic",
                "smoke",
                "semantic",
                "macros",
            ]
        ) {
            runSemanticAuthoringMacroSmoke()

            return []
        },
        TestFlow(
            "program-realization-authoring",
            tags: [
                "agentic",
                "smoke",
                "program",
                "realization",
            ]
        ) {
            runProgramRealizationSmoke()

            return []
        },
        TestFlow(
            "typed-tool-call",
            tags: [
                "agentic",
                "smoke",
                "tool",
                "typed",
            ]
        ) {
            let input = SmokeToolInput(
                rawValue: "typed-tool-smoke"
            )
            let result = try await DirectToolTest.call(
                SmokeTool(),
                input: input
            )

            try Expect.equal(
                result.output.value,
                input.rawValue,
                "direct typed tool output"
            )

            return [
                .field(
                    "tool",
                    result.tool.rawValue
                ),
                .field(
                    "input",
                    result.input.rawValue
                ),
                .field(
                    "output",
                    result.output.value
                ),
            ]
        },
        TestFlow(
            "domain-smoke",
            tags: [
                "agentic",
                "smoke",
                "domain",
            ]
        ) {
            AgenticTest.runDomainSmoke()

            return []
        },
    ]
}
