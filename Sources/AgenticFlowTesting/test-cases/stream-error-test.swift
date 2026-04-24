import Agentic

extension AgenticFlowTesting {
    static func runStreamError() async throws -> FlowTestResult {
        let harness = try await FlowHarness(
            name: FlowTestCase.stream_error.rawValue,
            delivery: .stream,
            maximumIterations: 1,
            adapter: .stream(
                batches: [
                    .init(
                        events: [
                            .messagedelta(.text("partial ")),
                            .messagedelta(.text("output")),
                        ],
                        error: .intentionalStreamFailure
                    )
                ]
            )
        )

        do {
            _ = try await harness.runner.run(
                request(),
                sessionID: harness.sessionID
            )

            throw FlowTestError.unexpectedResult(
                "stream-error unexpectedly completed"
            )
        } catch FlowTestError.intentionalStreamFailure {
            let checkpoint = try await harness.checkpoint()

            try assertEqual(
                checkpoint.phase,
                .failed,
                "checkpoint.phase"
            )

            try assertEqual(
                checkpoint.partialResponse?.message.content.text,
                "partial output",
                "checkpoint.partialResponse.text"
            )

            try assertHasEvents(
                checkpoint.events,
                [
                    .model_stream_started,
                    .assistant_delta,
                    .assistant_delta,
                    .model_stream_failed
                ]
            )

            return .passed(
                name: FlowTestCase.stream_error.rawValue,
                diagnostics: [
                    "phase=\(checkpoint.phase.rawValue)",
                    "partial=\(checkpoint.partialResponse?.message.content.text ?? "<nil>")",
                    "events=\(eventNames(checkpoint.events))"
                ]
            )
        }
    }
}
