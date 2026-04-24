public protocol AgentModelAdapter: Sendable {
    var response: AgentModelResponseProviding { get }
}

public protocol AgentModelResponseProviding: Sendable {
    func buffered(
        request: AgentRequest
    ) async throws -> AgentResponse

    func stream(
        request: AgentRequest
    ) -> AsyncThrowingStream<AgentStreamEvent, Error>
}

extension AgentModelAdapter {
    public func respond(
        request: AgentRequest
    ) async throws -> AgentResponse {
        try await response.buffered(request: request)
    }

    public func respond(
        request: AgentRequest,
        delivery: AgentModelResponseDelivery
    ) -> AsyncThrowingStream<AgentStreamEvent, Error> {
        response.respond(
            request: request,
            delivery: delivery
        )
    }
}

extension AgentModelResponseProviding {
    public func respond(
        request: AgentRequest,
        delivery: AgentModelResponseDelivery
    ) -> AsyncThrowingStream<AgentStreamEvent, Error> {
        switch delivery {
        case .buffered:
            bufferedStream(request: request)

        case .stream:
            stream(request: request)
        }
    }

    private func bufferedStream(
        request: AgentRequest
    ) -> AsyncThrowingStream<AgentStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let response = try await buffered(request: request)
                    continuation.yield(.completed(response))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
