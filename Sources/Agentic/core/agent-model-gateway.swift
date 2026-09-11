public protocol AgentModelGateway: Sendable {
    var identifier: AgentModelGatewayIdentifier { get }
    var response: AgentModelResponseProviding { get }
}

public protocol AgentModelResponseProviding: Sendable {
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
