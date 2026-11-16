public protocol AgentModelGateway: Sendable {
    var identifier: AgentModelGatewayIdentifier { get }
    var response: AgentModelResponseProviding { get }
}

public protocol AgentModelResponseProviding: Sendable {
    /// Explicit provider-side input counting. May perform a network request,
    /// but never generates a response. Nil means counting is unsupported;
    /// failures must throw rather than becoming zero or a lexical estimate.
    func countInputTokens(
        request: AgentRequest,
        route: AgentModelRoute,
        context: AgentModelInvocationContext
    ) async throws -> Int?

    func buffered(
        request: AgentRequest,
        route: AgentModelRoute,
        context: AgentModelInvocationContext
    ) async throws -> AgentResponse

    func stream(
        request: AgentRequest,
        route: AgentModelRoute,
        context: AgentModelInvocationContext
    ) -> AsyncThrowingStream<AgentStreamEvent, Error>
}

public extension AgentModelGateway {
    func respond(
        request: AgentRequest,
        route: AgentModelRoute,
        context: AgentModelInvocationContext = .default
    ) async throws -> AgentResponse {
        try await response.buffered(
            request: request,
            route: route,
            context: context
        )
    }

    func respond(
        request: AgentRequest,
        route: AgentModelRoute,
        delivery: AgentModelResponseDelivery,
        context: AgentModelInvocationContext = .default
    ) -> AsyncThrowingStream<AgentStreamEvent, Error> {
        response.respond(
            request: request,
            route: route,
            delivery: delivery,
            context: context
        )
    }
}

public extension AgentModelResponseProviding {
    func countInputTokens(
        request _: AgentRequest,
        route _: AgentModelRoute,
        context _: AgentModelInvocationContext
    ) async throws -> Int? {
        nil
    }

    func respond(
        request: AgentRequest,
        route: AgentModelRoute,
        delivery: AgentModelResponseDelivery,
        context: AgentModelInvocationContext
    ) -> AsyncThrowingStream<AgentStreamEvent, Error> {
        switch delivery {
        case .buffered:
            bufferedStream(
                request: request,
                route: route,
                context: context
            )

        case .stream:
            stream(
                request: request,
                route: route,
                context: context
            )
        }
    }

    private func bufferedStream(
        request: AgentRequest,
        route: AgentModelRoute,
        context: AgentModelInvocationContext
    ) -> AsyncThrowingStream<AgentStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let response = try await buffered(
                        request: request,
                        route: route,
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
