public protocol AgentResourceResolver:
    Sendable
{
    func resolve(
        _ resource: AgentResource
    ) async throws -> ResolvedAgentResource
}
