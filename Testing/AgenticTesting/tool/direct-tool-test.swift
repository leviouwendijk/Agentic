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

    public static func process<ToolType: Tool>(
        _ tool: ToolType,
        output: ToolType.Output,
        input: ToolType.Input
    ) throws -> ToolProjectionTestResult<ToolType> {
        let projection = try tool.process(
            output,
            input: input
        )

        return ToolProjectionTestResult(
            definition: ToolType.definition,
            input: input,
            output: output,
            projection: projection
        )
    }

    public static func classify<ToolType: Tool>(
        _ tool: ToolType,
        error: any Error,
        phase: ToolCall.Phase,
        input: ToolType.Input? = nil
    ) -> ToolClassificationTestResult<ToolType> {
        let incident = tool.classify(
            error,
            phase: phase,
            input: input
        )

        return ToolClassificationTestResult(
            definition: ToolType.definition,
            phase: phase,
            input: input,
            incident: incident
        )
    }

    public static func reconcile<ToolType: Tool>(
        _ tool: ToolType,
        input: ToolType.Input,
        after failure: ToolCall.Failure,
        workspace: WorkspaceContext? = nil
    ) async throws -> ToolReconciliationTestResult<ToolType> {
        let reconciliation = try await tool.reconcile(
            input,
            after: failure,
            workspace: workspace
        )

        return ToolReconciliationTestResult(
            definition: ToolType.definition,
            input: input,
            failure: failure,
            reconciliation: reconciliation
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
        let projection = try tool.process(
            output,
            input: input
        )

        return ToolTestResult(
            definition: ToolType.definition,
            input: input,
            preflight: preflight,
            output: output,
            projection: projection
        )
    }
}
