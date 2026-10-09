// Temporary aliases for consumers awaiting the binding migration.
// Remove once downstream AgenticRuntime no longer references these names.
@available(*, deprecated, renamed: "ToolBinding")
public typealias RegisteredTool = ToolBinding

@available(*, deprecated, renamed: "ToolBindingError")
public typealias RegisteredToolError = ToolBindingError

@available(*, deprecated, renamed: "ProgramBinding")
public typealias RegisteredProgram = ProgramBinding
