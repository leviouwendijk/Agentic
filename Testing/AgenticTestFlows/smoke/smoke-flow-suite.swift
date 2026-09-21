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
            ],
            operation: {
                try runSemanticAuthoringMacroSmoke()
                return []
            }
        ),
        TestFlow(
            "program-realization-authoring",
            tags: [
                "agentic",
                "smoke",
                "program",
                "realization",
            ],
            operation: {
                runProgramRealizationSmoke()
                return []
            }
        ),
        TestFlow(
            "typed-tool-characterization",
            tags: [
                "agentic",
                "smoke",
                "tool",
                "typed",
            ],
            operation: {
                let input = SmokeToolInput(
                    rawValue: "typed-tool-smoke"
                )
                let result = try await DirectToolTest.characterize(
                    SmokeTool(),
                    input: input
                )

                try Expect.equal(
                    result.output.value,
                    input.rawValue,
                    "direct typed tool output"
                )
                try Expect.equal(
                    result.preflight.tool.rawValue,
                    result.definition.identifier.rawValue,
                    "direct typed tool preflight preserves the Tool contract identifier"
                )

                return [
                    .field(
                        "tool",
                        result.definition.identifier.rawValue
                    ),
                    .field(
                        "input",
                        result.input.rawValue
                    ),
                    .field(
                        "preflight",
                        result.preflight.summary
                    ),
                    .field(
                        "output",
                        result.output.value
                    ),
                ]
            }
        ),
        TestFlow(
            "typed-program-run",
            tags: [
                "agentic",
                "smoke",
                "program",
                "typed",
            ],
            operation: {
                let input = SmokeDomain.Programs.MacroSmokeProgram.Input(
                    value: "typed-program-smoke"
                )
                let result = try await DirectProgramTest.run(
                    SmokeDomain.Programs.MacroSmokeProgram(),
                    input: input
                )

                try Expect.equal(
                    result.output.value,
                    input.value,
                    "direct typed Program output"
                )

                return [
                    .field(
                        "program",
                        result.definition.identifier.rawValue
                    ),
                    .field(
                        "input",
                        result.input.value
                    ),
                    .field(
                        "output",
                        result.output.value
                    ),
                ]
            }
        ),
        TestFlow(
            "domain-smoke",
            tags: [
                "agentic",
                "smoke",
                "domain",
            ],
            operation: {
                AgenticTest.runDomainSmoke()
                return []
            }
        ),
    ]
}
