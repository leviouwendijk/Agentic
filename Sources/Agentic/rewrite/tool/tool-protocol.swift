import Workspace

public protocol Tool:
    // ToolContract,
    Producer,
    ToolRecovery,
    ToolProjection
{
    // typealias Arguments = ToolInput
    // typealias Result = ToolOutput

    // REMOVED: Input and Output are canonically owned by ToolContract.
    // associatedtype Input: Arguments
    // associatedtype Output: Result

    // REMOVED: arbitrary per-tool environments recreate the generic construction problem.
    // associatedtype Environment: Sendable

    static var definition: ToolDefinition { get }

    func preflight(
        _ input: Input,
        workspace: WorkspaceContext?
    ) async throws -> ToolPreflight

    func call(
        _ input: Input,
        workspace: WorkspaceContext?
    ) async throws -> Output
}

public extension Tool {
    func preflight(
        _ input: Input,
        workspace: WorkspaceContext?
    ) async throws -> ToolPreflight {
        _ = input
        _ = workspace

        return ToolPreflight(
            tool: Self.definition.identifier,
            risk: Self.definition.risk,
            summary: Self.definition.purpose,
            sideEffects: Self.definition.risk.defaultSideEffects
        )
    }
}
