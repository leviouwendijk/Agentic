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

// @attached(memberAttribute)
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

// @attached(memberAttribute)
@attached(
    member,
    names:
        named(definition),
        named(Site)
)
@attached(
    extension,
    conformances: Program
)
public macro Program() = #externalMacro(
    module: "AgenticMacrosPlugin",
    type: "ProgramMacro"
)

@attached(accessor)
public macro InferenceSite() = #externalMacro(
    module: "AgenticMacrosPlugin",
    type: "InferenceSiteMacro"
)

// @attached(memberAttribute)
@attached(
    member,
    names: named(definition)
)
@attached(
    extension,
    conformances: Tool
)
public macro Tool(_ identifier: String? = nil) = #externalMacro(
    module: "AgenticMacrosPlugin",
    type: "ToolMacro"
)

/*
@attached(
    extension,
    conformances: SemanticInput
)
public macro _SemanticInput() = #externalMacro(
    module: "AgenticMacrosPlugin",
    type: "ContractConformanceMacro"
)

@attached(
    extension,
    conformances: SemanticOutput
)
public macro _SemanticOutput() = #externalMacro(
    module: "AgenticMacrosPlugin",
    type: "ContractConformanceMacro"
)

@attached(
    extension,
    conformances: InferredOutput
)
public macro _InferredOutput() = #externalMacro(
    module: "AgenticMacrosPlugin",
    type: "ContractConformanceMacro"
)

@attached(
    extension,
    conformances: ToolInput
)
public macro _ToolInput() = #externalMacro(
    module: "AgenticMacrosPlugin",
    type: "ContractConformanceMacro"
)

@attached(
    extension,
    conformances: ToolOutput
)
public macro _ToolOutput() = #externalMacro(
    module: "AgenticMacrosPlugin",
    type: "ContractConformanceMacro"
)
*/

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
