public protocol AgentModelAdapter: Sendable {
    func complete(
        request: AgentRequest
    ) async throws -> AgentResponse

    func completeStream(
        request: AgentRequest
    ) -> AsyncThrowingStream<AgentStreamEvent, Error>
}
