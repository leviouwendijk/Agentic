import Agentic
import TestFlows

extension AgenticFlowTesting {
    static func runStream() async throws -> [TestFlowDiagnostic] {
        let harness = try await FlowHarness(
            name: AgenticFlowSuite.ID.stream,
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

        return flowDiagnostics(
            response: "stream ok",
            checkpoint: checkpoint,
            events: result.events
        )
    }
}
