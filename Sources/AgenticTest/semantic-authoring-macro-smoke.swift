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
        struct Input {
            let value: String
        }

        struct Output {
            let value: String

            static var jsonschema: JSONSchema {
                .object()
            }
        }

        static let purpose =
            "Prove lexical Inference declaration synthesis."
    }

    @Inference
    struct MacroSmokeExplicitInference:
        Inference
    {
        struct Input:
            SemanticInput
        {
            let value: String
        }

        struct Output:
            InferredOutput
        {
            let value: String

            static var jsonschema: JSONSchema {
                .object()
            }
        }

        static let purpose =
            "Prove an explicit Inference conformance is not restated by its macro."
    }
}

extension SmokeDomain.Programs {
    @Program
    struct MacroSmokeProgram {
        struct Input {
            let value: String
        }

        struct Output {
            let value: String
        }

        static let purpose =
            "Prove lexical Program declaration synthesis."

        @InferenceSite
        static var compose:
            Site<SmokeDomain.Inferences.MacroSmokeInference>

        func run(
            _ input: Input,
            in _: ProgramContext
        ) async throws -> Output {
            .init(
                value: input.value
            )
        }
    }

    @Program
    struct MacroSmokeAliasedProgram {
        typealias Input =
            SmokeDomain.Inferences.MacroSmokeInference.Input
        typealias Output =
            SmokeDomain.Inferences.MacroSmokeInference.Output

        static let purpose =
            "Prove semantic contract aliases remain untouched."

        func run(
            _ input: Input,
            in _: ProgramContext
        ) async throws -> Output {
            .init(
                value: input.value
            )
        }
    }
}

extension SmokeDomain.Tools {
    @Tool
    struct MacroSmokeTool {
        struct Input {
            let value: String

            static var jsonschema: JSONSchema {
                .object()
            }
        }

        struct Output {
            let value: String
        }

        static let purpose =
            "Prove lexical Tool declaration synthesis."

        static let risk: ActionRisk = .observe

        func call(
            _ input: Input,
            workspace _: WorkspaceContext?
        ) async throws -> Output {
            .init(
                value: input.value
            )
        }
    }
}

extension SmokeDomain.Realizations {
    @InferenceRealization
    struct MacroSmokeInferenceRealization {
        typealias InferenceType =
            SmokeDomain.Inferences.MacroSmokeInference

        static let strategy:
            InferenceStrategyIdentifier = .direct

        static let instructions =
            "Use the direct smoke realization."
    }
}

extension SmokeDomain.Optimizations {
    @Optimization
    struct MacroSmokeOptimization {
        static let purpose =
            "Prove lexical Optimization declaration synthesis."
    }
}

func runSemanticAuthoringMacroSmoke() {
    requireAgent(
        SmokeDomain.Agents.MacroSmokeAgent.self
    )
    requireInference(
        SmokeDomain.Inferences.MacroSmokeInference.self
    )
    requireInference(
        SmokeDomain.Inferences.MacroSmokeExplicitInference.self
    )
    requireProgram(
        SmokeDomain.Programs.MacroSmokeProgram.self
    )
    requireProgram(
        SmokeDomain.Programs.MacroSmokeAliasedProgram.self
    )
    requireTool(
        SmokeDomain.Tools.MacroSmokeTool.self
    )
    requireInferenceRealization(
        SmokeDomain.Realizations.MacroSmokeInferenceRealization.self
    )
    requireOptimization(
        SmokeDomain.Optimizations.MacroSmokeOptimization.self
    )

    requireSemanticInput(
        SmokeDomain.Inferences.MacroSmokeInference.Input.self
    )
    requireInferredOutput(
        SmokeDomain.Inferences.MacroSmokeInference.Output.self
    )
    requireSemanticInput(
        SmokeDomain.Programs.MacroSmokeProgram.Input.self
    )
    requireSemanticOutput(
        SmokeDomain.Programs.MacroSmokeProgram.Output.self
    )
    requireToolInput(
        SmokeDomain.Tools.MacroSmokeTool.Input.self
    )
    requireToolOutput(
        SmokeDomain.Tools.MacroSmokeTool.Output.self
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
        SmokeDomain.Inferences.MacroSmokeExplicitInference.definition.identifier.rawValue,
        expected: "smoke_domain.inferences.macro_smoke_explicit_inference"
    )
    requireIdentifier(
        SmokeDomain.Programs.MacroSmokeProgram.definition.identifier.rawValue,
        expected: "smoke_domain.programs.macro_smoke_program"
    )
    requireIdentifier(
        SmokeDomain.Tools.MacroSmokeTool.definition.identifier.rawValue,
        expected: "smoke_domain.tools.macro_smoke_tool"
    )
    requireIdentifier(
        SmokeDomain.Optimizations.MacroSmokeOptimization.definition.identifier.rawValue,
        expected: "smoke_domain.optimizations.macro_smoke_optimization"
    )

    let realization =
        SmokeDomain.Realizations
            .MacroSmokeInferenceRealization
            .definition

    requireIdentifier(
        realization.identifier.rawValue,
        expected: "smoke_domain.realizations.macro_smoke_inference_realization"
    )

    guard realization.configuration.strategy == .direct else {
        fatalError(
            "Expected direct inference realization strategy."
        )
    }

    guard realization.configuration.budget == .singleAttempt else {
        fatalError(
            "Expected single-attempt inference budget default."
        )
    }

    do {
        _ = try InferenceBudget(
            maximumAttempts: 0
        )
        fatalError(
            "Expected invalid inference budget to be rejected."
        )
    } catch let error as InferenceBudgetParsingError {
        guard case .nonPositiveMaximumAttempts = error else {
            fatalError(
                "Unexpected inference budget parsing error: \(error)"
            )
        }
    } catch {
        fatalError(
            "Unexpected inference budget error: \(error)"
        )
    }

    _ = SmokeDomain.Realizations.self
    _ = SmokeDomain.Optimizations.self

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

private func requireSemanticInput<Value: SemanticInput>(
    _: Value.Type
) {}

private func requireSemanticOutput<Value: SemanticOutput>(
    _: Value.Type
) {}

private func requireInferredOutput<Value: InferredOutput>(
    _: Value.Type
) {}

private func requireToolInput<Value: ToolInput>(
    _: Value.Type
) {}

private func requireToolOutput<Value: ToolOutput>(
    _: Value.Type
) {}

private func requireInferenceRealization<
    Value: InferenceRealization
>(
    _: Value.Type
) {}

private func requireOptimization<Value: Optimization>(
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
