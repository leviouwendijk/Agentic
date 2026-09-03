public protocol AgentModelAdapter: Sendable {
    var response: AgentModelResponseProviding { get }
}

public protocol AgentModelResponseProviding: Sendable {
    func buffered(
        request: AgentRequest
    ) async throws -> AgentResponse

    func buffered(
        request: AgentRequest,
        context: AgentModelInvocationContext
    ) async throws -> AgentResponse

    func stream(
        request: AgentRequest
    ) -> AsyncThrowingStream<AgentStreamEvent, Error>

    func stream(
        request: AgentRequest,
        context: AgentModelInvocationContext
    ) -> AsyncThrowingStream<AgentStreamEvent, Error>
}

extension AgentModelAdapter {
    public func respond(
        request: AgentRequest
    ) async throws -> AgentResponse {
        try await respond(
            request: request,
            context: .default
        )
    }

    public func respond(
        request: AgentRequest,
        context: AgentModelInvocationContext
    ) async throws -> AgentResponse {
        try await response.buffered(
            request: request,
            context: context
        )
    }

    public func respond(
        request: AgentRequest,
        delivery: AgentModelResponseDelivery
    ) -> AsyncThrowingStream<AgentStreamEvent, Error> {
        respond(
            request: request,
            delivery: delivery,
            context: .default
        )
    }

    public func respond(
        request: AgentRequest,
        delivery: AgentModelResponseDelivery,
        context: AgentModelInvocationContext
    ) -> AsyncThrowingStream<AgentStreamEvent, Error> {
        response.respond(
            request: request,
            delivery: delivery,
            context: context
        )
    }
}

extension AgentModelResponseProviding {
    public func buffered(
        request: AgentRequest,
        context _: AgentModelInvocationContext
    ) async throws -> AgentResponse {
        try await buffered(
            request: request
        )
    }

    public func stream(
        request: AgentRequest,
        context _: AgentModelInvocationContext
    ) -> AsyncThrowingStream<AgentStreamEvent, Error> {
        stream(
            request: request
        )
    }

    public func respond(
        request: AgentRequest,
        delivery: AgentModelResponseDelivery
    ) -> AsyncThrowingStream<AgentStreamEvent, Error> {
        respond(
            request: request,
            delivery: delivery,
            context: .default
        )
    }

    public func respond(
        request: AgentRequest,
        delivery: AgentModelResponseDelivery,
        context: AgentModelInvocationContext
    ) -> AsyncThrowingStream<AgentStreamEvent, Error> {
        switch delivery {
        case .buffered:
            bufferedStream(
                request: request,
                context: context
            )

        case .stream:
            stream(
                request: request,
                context: context
            )
        }
    }

    private func bufferedStream(
        request: AgentRequest,
        context: AgentModelInvocationContext
    ) -> AsyncThrowingStream<AgentStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let response = try await buffered(
                        request: request,
                        context: context
                    )
                    continuation.yield(
                        .completed(response)
                    )
                    continuation.finish()
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
}
