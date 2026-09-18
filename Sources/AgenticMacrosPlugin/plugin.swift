import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AgenticMacrosPlugin:
    CompilerPlugin
{
    let providingMacros: [Macro.Type] = [
        DomainMacro.self,
        AgentMacro.self,
        InferenceMacro.self,
        ProgramMacro.self,
        ToolMacro.self,
        InferenceRealizationMacro.self,
        OptimizationMacro.self,
    ]
}
