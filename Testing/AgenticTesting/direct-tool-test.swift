import Agentic
import Workspace

public struct DirectToolTestResult<Input: Sendable, Output: Sendable>: Sendable {
    public let tool: ToolIdentifier
    public let input: Input
    public let output: Output

    public init(
        tool: ToolIdentifier,
        input: Input,
        output: Output
    ) {
        self.tool = tool
        self.input = input
        self.output = output
    }
}

public enum DirectToolTest {
    public static func call<ToolType: Tool>(
        _ tool: ToolType,
        input: ToolType.Input,
        workspace: WorkspaceContext? = nil
    ) async throws -> DirectToolTestResult<ToolType.Input, ToolType.Output> {
        let output = try await tool.call(
            input,
            workspace: workspace
        )

        return DirectToolTestResult(
            tool: ToolType.definition.identifier,
            input: input,
            output: output
        )
    }
}
