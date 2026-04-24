import Agentic

extension AgenticFlowTesting {
    static func runBuffered() async throws -> FlowTestResult {
        let harness = try await FlowHarness(
            name: FlowTestCase.buffered.rawValue,
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

        return .passed(
            name: FlowTestCase.buffered.rawValue,
            diagnostics: [
                "response=buffered ok",
                "phase=\(checkpoint.phase.rawValue)",
                "events=\(eventNames(result.events))"
            ]
        )
    }
}
