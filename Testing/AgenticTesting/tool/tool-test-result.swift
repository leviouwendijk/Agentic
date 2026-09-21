import Agentic

public struct ToolPreflightTestResult<ToolType: Tool>: Sendable {
    public let definition: ToolDefinition
    public let input: ToolType.Input
    public let preflight: ToolPreflight

    public init(
        definition: ToolDefinition,
        input: ToolType.Input,
        preflight: ToolPreflight
    ) {
        self.definition = definition
        self.input = input
        self.preflight = preflight
    }
}

public struct ToolCallTestResult<ToolType: Tool>: Sendable {
    public let definition: ToolDefinition
    public let input: ToolType.Input
    public let output: ToolType.Output

    public init(
        definition: ToolDefinition,
        input: ToolType.Input,
        output: ToolType.Output
    ) {
        self.definition = definition
        self.input = input
        self.output = output
    }
}

public struct ToolTestResult<ToolType: Tool>: Sendable {
    public let definition: ToolDefinition
    public let input: ToolType.Input
    public let preflight: ToolPreflight
    public let output: ToolType.Output

    public init(
        definition: ToolDefinition,
        input: ToolType.Input,
        preflight: ToolPreflight,
        output: ToolType.Output
    ) {
        self.definition = definition
        self.input = input
        self.preflight = preflight
        self.output = output
    }
}
