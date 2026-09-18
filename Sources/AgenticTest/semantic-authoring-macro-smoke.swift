import Agentic
import Schema
import Workspace

extension SmokeDomain.Agents {
    @Agent
    enum MacroSmokeAgent {
        static let purpose =
            "Prove lexical Agent declaration synthesis."
    }
}

extension SmokeDomain.Inferences {
    @Inference
    struct MacroSmokeInference {
        struct Input:
            Codable,
            Sendable
        {
            let value: String
        }

        struct Output:
            JSONSchemaProviding,
            Codable,
            Sendable
        {
            let value: String

            static var jsonschema: JSONSchema {
                .object()
            }
        }

        static let purpose =
            "Prove lexical Inference declaration synthesis."
    }
}

struct MacroSmokeProgramInput:
    Codable,
    Sendable
{
    let value: String
}

struct MacroSmokeProgramOutput:
    Codable,
    Sendable
{
    let value: String
}

extension SmokeDomain.Programs {
    @Program
    struct MacroSmokeProgram {
        typealias Input = MacroSmokeProgramInput
        typealias Output = MacroSmokeProgramOutput

        static let purpose =
            "Prove lexical Program declaration synthesis."
    }
}

extension SmokeDomain.Tools {
    @Tool
    struct MacroSmokeTool {
        typealias Input = SmokeToolInput
        typealias Output = SmokeToolOutput

        static let purpose =
            "Prove lexical Tool declaration synthesis."

        static let risk: ActionRisk = .observe

        func call(
            _ input: Input,
            workspace _: WorkspaceContext?
        ) async throws -> Output {
            .init(
                value: input.rawValue
            )
        }
    }
}

func runSemanticAuthoringMacroSmoke() {
    requireAgent(
        SmokeDomain.Agents.MacroSmokeAgent.self
    )
    requireInference(
        SmokeDomain.Inferences.MacroSmokeInference.self
    )
    requireProgram(
        SmokeDomain.Programs.MacroSmokeProgram.self
    )
    requireTool(
        SmokeDomain.Tools.MacroSmokeTool.self
    )

    requireIdentifier(
        SmokeDomain.Agents.MacroSmokeAgent.definition.identifier.rawValue,
        expected: "smoke_domain.agents.macro_smoke_agent"
    )
    requireIdentifier(
        SmokeDomain.Inferences.MacroSmokeInference.definition.identifier.rawValue,
        expected: "smoke_domain.inferences.macro_smoke_inference"
    )
    requireIdentifier(
        SmokeDomain.Programs.MacroSmokeProgram.definition.identifier.rawValue,
        expected: "smoke_domain.programs.macro_smoke_program"
    )
    requireIdentifier(
        SmokeDomain.Tools.MacroSmokeTool.definition.identifier.rawValue,
        expected: "smoke_domain.tools.macro_smoke_tool"
    )

    _ = SmokeDomain.Realizations.self

    print("PASS: semantic authoring macros")
}

private func requireAgent<Value: Agent>(
    _: Value.Type
) {}

private func requireInference<Value: Inference>(
    _: Value.Type
) {}

private func requireProgram<Value: Program>(
    _: Value.Type
) {}

private func requireTool<Value: Tool>(
    _: Value.Type
) {}

private func requireIdentifier(
    _ actual: String,
    expected: String
) {
    guard actual == expected else {
        fatalError(
            "Expected semantic identifier '\(expected)', got '\(actual)'."
        )
    }
}
