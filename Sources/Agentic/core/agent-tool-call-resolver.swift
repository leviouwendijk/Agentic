public protocol AgentToolCallResolver:
    Sendable
{
    func resolve(
        _ call: AgentToolCall
    ) async throws -> AgentToolResult
}
