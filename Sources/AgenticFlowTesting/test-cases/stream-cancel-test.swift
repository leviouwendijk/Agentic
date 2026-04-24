import Agentic
import TestFlows

extension AgenticFlowTesting {
    static func runStreamCancel() async throws -> [TestFlowDiagnostic] {
        let harness = try await FlowHarness(
            name: AgenticFlowSuite.ID.stream_cancel,
            delivery: .stream,
            maximumIterations: 1,
            adapter: .stream(
                batches: [
                    .init(
                        events: [
                            .messagedelta(.text("cancel ")),
                            .messagedelta(.text("partial ")),
                            .messagedelta(.text("tail")),
                            .completed(
                                response(
                                    text: "should not complete",
                                    stopReason: .end_turn
                                )
                            ),
                        ],
                        nanosecondsBetweenEvents: 75_000_000
                    )
                ]
            )
        )

        let task = Task {
            try await harness.runner.run(
                request(),
                sessionID: harness.sessionID
            )
        }

        try await Task.sleep(
            nanoseconds: 115_000_000
        )

        task.cancel()

        do {
            _ = try await task.value

            throw FlowTestError.unexpectedResult(
                "stream-cancel unexpectedly completed"
            )
        } catch is CancellationError {
            let checkpoint = try await harness.checkpoint()

            try Expect.equal(
                checkpoint.phase,
                .interrupted,
                "checkpoint.phase"
            )

            let partialText = try Expect.hasPrefix(
                checkpoint.partialResponse?.message.content.text,
                "cancel",
                "checkpoint.partialResponse.text"
            )

            try assertHasEvents(
                checkpoint.events,
                [
                    .model_stream_started,
                    .assistant_delta,
                    .model_stream_interrupted
                ]
            )

            return flowDiagnostics(
                partial: partialText,
                checkpoint: checkpoint,
                events: checkpoint.events
            )
        }
    }
}
