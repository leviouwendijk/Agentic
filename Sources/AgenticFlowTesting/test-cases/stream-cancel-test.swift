import Agentic
import Foundation

extension AgenticFlowTesting {
    static func runStreamCancel() async throws -> FlowTestResult {
        let harness = try await FlowHarness(
            name: FlowTestCase.stream_cancel.rawValue,
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

            try assertEqual(
                checkpoint.phase,
                .interrupted,
                "checkpoint.phase"
            )

            guard let partialText = checkpoint.partialResponse?.message.content.text,
                  partialText.hasPrefix("cancel") else {
                throw FlowTestError.assertionFailed(
                    "expected partial response beginning with 'cancel', got '\(checkpoint.partialResponse?.message.content.text ?? "<nil>")'"
                )
            }

            try assertHasEvents(
                checkpoint.events,
                [
                    .model_stream_started,
                    .assistant_delta,
                    .model_stream_interrupted
                ]
            )

            return .passed(
                name: FlowTestCase.stream_cancel.rawValue,
                diagnostics: [
                    "phase=\(checkpoint.phase.rawValue)",
                    "partial=\(partialText)",
                    "events=\(eventNames(checkpoint.events))"
                ]
            )
        }
    }
}
