public protocol ToolCallResolver:
    Sendable
{
    func resolve(
        _ call: ToolCall
    ) async throws -> ToolResult
}
