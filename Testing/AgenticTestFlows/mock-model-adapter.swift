import Agentic
import Foundation

struct MockModelAdapter: AgentModelAdapter {
    let provider: MockModelResponseProvider

    var response: AgentModelResponseProviding {
        provider
    }

    static func buffered(
        text: String
    ) -> Self {
        let response = AgenticFlowTesting.response(
            text: text,
            stopReason: .end_turn
        )

        return .init(
            provider: .init(
                bufferedResponses: [
                    response
                ],
                streamBatches: [
                    .init(
                        events: [
                            .completed(response)
                        ]
                    )
                ]
            )
        )
    }

    static func stream(
        batches: [MockStreamBatch]
    ) -> Self {
        let fallbackResponse = AgenticFlowTesting.response(
            text: "",
            stopReason: .error
        )

        let bufferedResponses = batches.compactMap { batch in
            batch.events.compactMap { event -> AgentResponse? in
                guard case .completed(let response) = event else {
                    return nil
                }

                return response
            }.last
        }

        return .init(
            provider: .init(
                bufferedResponses: bufferedResponses.isEmpty
                    ? [fallbackResponse]
                    : bufferedResponses,
                streamBatches: batches.isEmpty
                    ? [
                        .init(
                            events: [
                                .completed(fallbackResponse)
                            ]
                        )
                    ]
                    : batches
            )
        )
    }
}

actor MockModelResponseProvider: AgentModelResponseProviding {
    private var bufferedResponses: [AgentResponse]
    private var streamBatches: [MockStreamBatch]
    private var bufferedCallIndex: Int = 0
    private var streamCallIndex: Int = 0

    init(
        bufferedResponses: [AgentResponse],
        streamBatches: [MockStreamBatch]
    ) {
        self.bufferedResponses = bufferedResponses
        self.streamBatches = streamBatches
    }

    func buffered(
        request: AgentRequest
    ) async throws -> AgentResponse {
        _ = request

        let index = min(
            bufferedCallIndex,
            max(
                0,
                bufferedResponses.count - 1
            )
        )

        bufferedCallIndex += 1

        return bufferedResponses[index]
    }

    nonisolated func stream(
        request: AgentRequest
    ) -> AsyncThrowingStream<AgentStreamEvent, Error> {
        _ = request

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let batch = await nextStreamBatch()

                    for event in batch.events {
                        try Task.checkCancellation()

                        if batch.nanosecondsBetweenEvents > 0 {
                            try await Task.sleep(
                                nanoseconds: batch.nanosecondsBetweenEvents
                            )
                        }

                        continuation.yield(
                            event
                        )
                    }

                    if let error = batch.error {
                        continuation.finish(
                            throwing: error
                        )
                    } else {
                        continuation.finish()
                    }
                } catch {
                    continuation.finish(
                        throwing: error
                    )
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func nextStreamBatch() -> MockStreamBatch {
        let index = min(
            streamCallIndex,
            max(
                0,
                streamBatches.count - 1
            )
        )

        streamCallIndex += 1

        return streamBatches[index]
    }
}
