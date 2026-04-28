public protocol AgentAdvisorModelProviding: Sendable {
    func route(
        request: AgentRequest,
        policy: AgentModelUsePolicy
    ) throws -> AgentModelRouteResult

    func buffered(
        request: AgentRequest,
        policy: AgentModelUsePolicy
    ) async throws -> AgentResponse
}
