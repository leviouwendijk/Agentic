import Agentic
import TestFlows

extension AgenticFlowTesting {
    static func runBuffered() async throws -> [TestFlowDiagnostic] {
        let harness = try await FlowHarness(
            name: AgenticFlowSuite.ID.buffered,
            delivery: .buffered,
            maximumIterations: 1,
            adapter: .buffered(
                text: "buffered ok"
            )
        )

        let result = try await harness.runner.run(
            request(),
            sessionID: harness.sessionID
        )
        let checkpoint = try await harness.checkpoint()

        try assertCompleted(
            result: result,
            checkpoint: checkpoint,
            expectedText: "buffered ok",
            expectedEvents: [
                .assistant_response
            ]
        )

        return flowDiagnostics(
            response: "buffered ok",
            checkpoint: checkpoint,
            events: result.events
        )
    }
}
