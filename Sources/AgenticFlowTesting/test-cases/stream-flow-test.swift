import Agentic

extension AgenticFlowTesting {
    static func runStream() async throws -> FlowTestResult {
        let harness = try await FlowHarness(
            name: FlowTestCase.stream.rawValue,
            delivery: .stream,
            maximumIterations: 1,
            adapter: .stream(
                batches: [
                    .init(
                        events: [
                            .messagedelta(.text("stream ")),
                            .messagedelta(.text("ok")),
                            .completed(
                                response(
                                    text: "stream ok",
                                    stopReason: .end_turn
                                )
                            ),
                        ]
                    )
                ]
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
            expectedText: "stream ok",
            expectedEvents: [
                .model_stream_started,
                .assistant_delta,
                .assistant_delta,
                .model_stream_completed,
                .assistant_response
            ]
        )

        return .passed(
            name: FlowTestCase.stream.rawValue,
            diagnostics: [
                "response=stream ok",
                "phase=\(checkpoint.phase.rawValue)",
                "events=\(eventNames(result.events))"
            ]
        )
    }
}
