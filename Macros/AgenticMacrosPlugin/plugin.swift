import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AgenticMacrosPlugin: CompilerPlugin  {
    let providingMacros: [Macro.Type] = [
        DomainMacro.self,
        AgentMacro.self,
        InstructionMacro.self,
        InferenceMacro.self,
        ProgramMacro.self,
        InferenceSiteMacro.self,
        ToolMacro.self,
        AdapterMacro.self,
        InferenceRealizationMacro.self,
        OptimizationMacro.self,
    ]
}
