import Agentic
import Workspace

public enum DirectToolTest {
    public static func preflight<ToolType: Tool>(
        _ tool: ToolType,
        input: ToolType.Input,
        workspace: WorkspaceContext? = nil
    ) async throws -> ToolPreflightTestResult<ToolType> {
        let preflight = try await tool.preflight(
            input,
            workspace: workspace
        )

        return ToolPreflightTestResult(
            definition: ToolType.definition,
            input: input,
            preflight: preflight
        )
    }

    public static func call<ToolType: Tool>(
        _ tool: ToolType,
        input: ToolType.Input,
        workspace: WorkspaceContext? = nil
    ) async throws -> ToolCallTestResult<ToolType> {
        let output = try await tool.call(
            input,
            workspace: workspace
        )

        return ToolCallTestResult(
            definition: ToolType.definition,
            input: input,
            output: output
        )
    }

    public static func characterize<ToolType: Tool>(
        _ tool: ToolType,
        input: ToolType.Input,
        workspace: WorkspaceContext? = nil
    ) async throws -> ToolTestResult<ToolType> {
        let preflight = try await tool.preflight(
            input,
            workspace: workspace
        )
        let output = try await tool.call(
            input,
            workspace: workspace
        )

        return ToolTestResult(
            definition: ToolType.definition,
            input: input,
            preflight: preflight,
            output: output
        )
    }
}
