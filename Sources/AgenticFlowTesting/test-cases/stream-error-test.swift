import Agentic
import TestFlows

extension AgenticFlowTesting {
    static func runStreamError() async throws -> [TestFlowDiagnostic] {
        let harness = try await FlowHarness(
            name: AgenticFlowSuite.ID.stream_error,
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

            try Expect.equal(
                checkpoint.phase,
                .failed,
                "checkpoint.phase"
            )

            try Expect.equal(
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

            return flowDiagnostics(
                partial: checkpoint.partialResponse?.message.content.text ?? "<nil>",
                checkpoint: checkpoint,
                events: checkpoint.events
            )
        }
    }
}
