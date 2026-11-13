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

public struct ToolProjectionTestResult<ToolType: Tool>: Sendable {
    public let definition: ToolDefinition
    public let input: ToolType.Input
    public let output: ToolType.Output
    public let projection: ToolExecution.Projection?

    public init(
        definition: ToolDefinition,
        input: ToolType.Input,
        output: ToolType.Output,
        projection: ToolExecution.Projection?
    ) {
        self.definition = definition
        self.input = input
        self.output = output
        self.projection = projection
    }
}

public struct ToolClassificationTestResult<ToolType: Tool>: Sendable {
    public let definition: ToolDefinition
    public let phase: ToolExecution.Phase
    public let input: ToolType.Input?
    public let incident: Recovery.Incident?

    public init(
        definition: ToolDefinition,
        phase: ToolExecution.Phase,
        input: ToolType.Input?,
        incident: Recovery.Incident?
    ) {
        self.definition = definition
        self.phase = phase
        self.input = input
        self.incident = incident
    }
}

public struct ToolReconciliationTestResult<ToolType: Tool>: Sendable {
    public let definition: ToolDefinition
    public let input: ToolType.Input
    public let failure: ToolExecution.Failure
    public let reconciliation: ToolExecution.Reconciliation<ToolType.Output>?

    public init(
        definition: ToolDefinition,
        input: ToolType.Input,
        failure: ToolExecution.Failure,
        reconciliation: ToolExecution.Reconciliation<ToolType.Output>?
    ) {
        self.definition = definition
        self.input = input
        self.failure = failure
        self.reconciliation = reconciliation
    }
}

public struct ToolTestResult<ToolType: Tool>: Sendable {
    public let definition: ToolDefinition
    public let input: ToolType.Input
    public let preflight: ToolPreflight
    public let output: ToolType.Output
    public let projection: ToolExecution.Projection?

    public init(
        definition: ToolDefinition,
        input: ToolType.Input,
        preflight: ToolPreflight,
        output: ToolType.Output,
        projection: ToolExecution.Projection?
    ) {
        self.definition = definition
        self.input = input
        self.preflight = preflight
        self.output = output
        self.projection = projection
    }
}
