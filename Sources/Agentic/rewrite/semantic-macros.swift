@attached(
    member,
    names: named(definition)
)
@attached(
    extension,
    conformances: Agent
)
public macro Agent() = #externalMacro(
    module: "AgenticMacrosPlugin",
    type: "AgentMacro"
)

@attached(
    member,
    names: named(definition)
)
@attached(
    extension,
    conformances: Inference
)
public macro Inference() = #externalMacro(
    module: "AgenticMacrosPlugin",
    type: "InferenceMacro"
)

@attached(
    member,
    names: named(definition)
)
@attached(
    extension,
    conformances: Program
)
public macro Program() = #externalMacro(
    module: "AgenticMacrosPlugin",
    type: "ProgramMacro"
)

@attached(
    member,
    names: named(definition)
)
@attached(
    extension,
    conformances: Tool
)
public macro Tool() = #externalMacro(
    module: "AgenticMacrosPlugin",
    type: "ToolMacro"
)

@attached(
    member,
    names: named(definition)
)
@attached(
    extension,
    conformances: InferenceRealization
)
public macro InferenceRealization() = #externalMacro(
    module: "AgenticMacrosPlugin",
    type: "InferenceRealizationMacro"
)

@attached(
    member,
    names: named(definition)
)
@attached(
    extension,
    conformances: Optimization
)
public macro Optimization() = #externalMacro(
    module: "AgenticMacrosPlugin",
    type: "OptimizationMacro"
)
