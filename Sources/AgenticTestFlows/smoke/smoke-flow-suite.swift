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
