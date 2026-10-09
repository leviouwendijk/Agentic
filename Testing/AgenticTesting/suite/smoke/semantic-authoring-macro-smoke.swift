import Agentic
import Schema
import Workspace

extension SmokeDomain.Agents {
    @Agent
    enum MacroSmokeAgent {
        struct Input: Source {
            let objective: String

            static var jsonschema: JSONSchema {
                .object()
            }
        }

        struct Output: Result {
            let summary: String

            static var jsonschema: JSONSchema {
                .object()
            }
        }

        static let purpose =
            "Prove lexical Agent declaration synthesis."

        static let capabilities = AgentCapabilities(
            available: .init(
                tools: .init(
                    members: [
                        SmokeDomain.Tools.MacroSmokeTool.identifier,
                    ]
                )
            ),
            visible: .init(
                tools: .init(
                    members: [
                        SmokeDomain.Tools.MacroSmokeTool.identifier,
                    ]
                )
            )
        )

        static let modelSelection = AgentModelSelection(
            purpose: .coder
        )

        static let instructions: Instructions = [
            .instruction(.init(
                identifier: "smoke.authoring",
                content: "Respect observed evidence."
            )),
            .text("Investigate the fixture."),
        ]
    }
}

extension SmokeDomain.Inferences {
    @Inference
    struct MacroSmokeInference {
        struct Input: Source {
            let value: String

            static var jsonschema: JSONSchema {
                .object()
            }
        }

        struct Output: Result {
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
        struct Input: Source {
            let value: String

            static var jsonschema: JSONSchema {
                .object()
            }
        }

        struct Output: Result {
            let value: String

            static var jsonschema: JSONSchema {
                .object()
            }
        }

        static let purpose =
            "Prove an explicit Inference conformance is not restated by its macro."
    }

    @Inference(.generative)
    struct MacroSmokeGenerativeInference {
        typealias Input = MacroSmokeInference.Input
        typealias Output = MacroSmokeInference.Output

        static let purpose =
            "Prove explicit generative inference declaration synthesis."
    }

    @Inference(.decision)
    struct MacroSmokeDecisionInference {
        typealias Input = MacroSmokeInference.Input
        typealias Output = Decision.Probability

        static let purpose =
            "Prove decision inference declaration synthesis."

        static func decision(
            for input: Input
        ) throws -> Decision.Specification<Output> {
            try .init(
                state: input,
                query: Decision.binary(
                    instructions:
                        "Does this smoke-test decision apply?"
                )
            )
        }
    }
}

extension SmokeDomain.Programs {
    @Program
    struct MacroSmokeProgram {
        struct Input: Source {
            let value: String

            static var jsonschema: JSONSchema {
                .object()
            }
        }

        struct Output: Result {
            let value: String

            static var jsonschema: JSONSchema {
                .object()
            }
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
        struct Input: Source {
            let value: String

            static var jsonschema: JSONSchema {
                .object()
            }
        }

        struct Output: Result {
            let value: String

            static var jsonschema: JSONSchema {
                .object()
            }
        }

        static let purpose =
            "Prove inferred flat Tool identifier synthesis."

        static let risk: ActionRisk = .observe

        func call(
            _ input: Input,
            in _: ToolContext
        ) async throws -> Output {
            .init(
                value: input.value
            )
        }
    }

    @Tool("explicit_tool")
    struct MacroSmokeExplicitTool: Tool {
        struct Input: Source {
            let value: String

            static var jsonschema: JSONSchema {
                .object()
            }
        }

        struct Output: Result {
            let value: String

            static var jsonschema: JSONSchema {
                .object()
            }
        }

        static let purpose =
            "Prove explicit Tool conformance and identifier override semantics."

        static let risk: ActionRisk = .observe

        func call(
            _ input: Input,
            in _: ToolContext
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

        static let instructions: Instructions = [
            .instruction(.init(
                identifier: "smoke.authoring",
                content: "Respect observed evidence."
            )),
            .text("Use the direct smoke realization."),
        ]
    }
}

extension SmokeDomain.Optimizations {
    @Optimization
    struct MacroSmokeOptimization {
        static let purpose =
            "Prove lexical Optimization declaration synthesis."
    }
}

private func requireDecisionInference<InferenceType: DecisionInference>(
    _: InferenceType.Type
) {}

func runSemanticAuthoringMacroSmoke() throws {
    ContractProof.agent(
        SmokeDomain.Agents.MacroSmokeAgent.self
    )
    ContractProof.source(
        SmokeDomain.Agents.MacroSmokeAgent.Input.self
    )
    ContractProof.result(
        SmokeDomain.Agents.MacroSmokeAgent.Output.self
    )
    ContractProof.inference(
        SmokeDomain.Inferences.MacroSmokeInference.self
    )
    ContractProof.inference(
        SmokeDomain.Inferences.MacroSmokeExplicitInference.self
    )
    ContractProof.inference(
        SmokeDomain.Inferences.MacroSmokeGenerativeInference.self
    )
    ContractProof.inference(
        SmokeDomain.Inferences.MacroSmokeDecisionInference.self
    )
    requireDecisionInference(
        SmokeDomain.Inferences.MacroSmokeDecisionInference.self
    )
    ContractProof.program(
        SmokeDomain.Programs.MacroSmokeProgram.self
    )
    ContractProof.program(
        SmokeDomain.Programs.MacroSmokeAliasedProgram.self
    )
    ContractProof.tool(
        SmokeDomain.Tools.MacroSmokeTool.self
    )
    ContractProof.tool(
        SmokeDomain.Tools.MacroSmokeExplicitTool.self
    )
    ContractProof.inferenceRealization(
        SmokeDomain.Realizations.MacroSmokeInferenceRealization.self
    )
    ContractProof.optimization(
        SmokeDomain.Optimizations.MacroSmokeOptimization.self
    )

    ContractProof.source(
        SmokeDomain.Inferences.MacroSmokeInference.Input.self
    )
    ContractProof.result(
        SmokeDomain.Inferences.MacroSmokeInference.Output.self
    )
    ContractProof.source(
        SmokeDomain.Programs.MacroSmokeProgram.Input.self
    )
    ContractProof.result(
        SmokeDomain.Programs.MacroSmokeProgram.Output.self
    )
    ContractProof.source(
        SmokeDomain.Tools.MacroSmokeTool.Input.self
    )
    ContractProof.result(
        SmokeDomain.Tools.MacroSmokeTool.Output.self
    )
    ContractProof.source(
        SmokeDomain.Tools.MacroSmokeExplicitTool.Input.self
    )
    ContractProof.result(
        SmokeDomain.Tools.MacroSmokeExplicitTool.Output.self
    )

    try ContractProof.identifier(
        SmokeDomain.Agents.MacroSmokeAgent.definition.identifier.rawValue,
        expected: "smoke_domain.agents.macro_smoke_agent"
    )

    guard SmokeDomain.Agents
        .MacroSmokeAgent
        .definition
        .modelSelection
        .purpose == .coder
    else {
        fatalError(
            "Expected @Agent to retain authored model selection."
        )
    }

    guard SmokeDomain.Agents
        .MacroSmokeAgent
        .definition
        .capabilities
        .available
        .tools
        .members
            == [
                SmokeDomain.Tools.MacroSmokeTool.identifier,
            ]
    else {
        fatalError(
            "Expected @Agent to retain authored available capabilities."
        )
    }

    guard SmokeDomain.Agents
        .MacroSmokeAgent
        .definition
        .capabilities
        .visible
        .tools
        .members
            == [
                SmokeDomain.Tools.MacroSmokeTool.identifier,
            ]
    else {
        fatalError(
            "Expected @Agent to retain authored visible capabilities."
        )
    }

    try ContractProof.identifier(
        SmokeDomain.Inferences.MacroSmokeInference.definition.identifier.rawValue,
        expected: "smoke_domain.inferences.macro_smoke_inference"
    )
    try ContractProof.identifier(
        SmokeDomain.Inferences.MacroSmokeExplicitInference.definition.identifier.rawValue,
        expected: "smoke_domain.inferences.macro_smoke_explicit_inference"
    )
    try ContractProof.identifier(
        SmokeDomain.Inferences.MacroSmokeGenerativeInference.definition.identifier.rawValue,
        expected: "smoke_domain.inferences.macro_smoke_generative_inference"
    )
    try ContractProof.identifier(
        SmokeDomain.Inferences.MacroSmokeDecisionInference.definition.identifier.rawValue,
        expected: "smoke_domain.inferences.macro_smoke_decision_inference"
    )

    switch try SmokeDomain.Inferences
        .MacroSmokeInference
        .specification(
            for: .init(
                value: "default"
            )
        )
    {
    case .generative:
        break

    case .decision:
        fatalError(
            "Expected plain @Inference to remain generative."
        )
    }

    switch try SmokeDomain.Inferences
        .MacroSmokeGenerativeInference
        .specification(
            for: .init(
                value: "explicit-generative"
            )
        )
    {
    case .generative:
        break

    case .decision:
        fatalError(
            "Expected @Inference(.generative) to synthesize generative inference semantics."
        )
    }

    switch try SmokeDomain.Inferences
        .MacroSmokeDecisionInference
        .specification(
            for: .init(
                value: "decision"
            )
        )
    {
    case .generative:
        fatalError(
            "Expected @Inference(.decision) to synthesize decision inference semantics."
        )

    case .decision(let specification):
        guard specification.query.questions.count == 1 else {
            fatalError(
                "Expected decision inference smoke fixture to retain its authored query."
            )
        }
    }

    try ContractProof.identifier(
        SmokeDomain.Programs.MacroSmokeProgram.definition.identifier.rawValue,
        expected: "smoke_domain.programs.macro_smoke_program"
    )
    try ContractProof.identifier(
        SmokeDomain.Tools.MacroSmokeTool.identifier.rawValue,
        expected: "macro_smoke_tool"
    )
    try ContractProof.identifier(
        SmokeDomain.Tools.MacroSmokeTool.definition.identifier.rawValue,
        expected: "macro_smoke_tool"
    )
    try ContractProof.identifier(
        SmokeDomain.Tools.MacroSmokeExplicitTool.identifier.rawValue,
        expected: "explicit_tool"
    )
    try ContractProof.identifier(
        SmokeDomain.Tools.MacroSmokeExplicitTool.definition.identifier.rawValue,
        expected: "explicit_tool"
    )
    try ContractProof.identifier(
        SmokeDomain.Optimizations.MacroSmokeOptimization.definition.identifier.rawValue,
        expected: "smoke_domain.optimizations.macro_smoke_optimization"
    )

    let realization =
        SmokeDomain.Realizations
            .MacroSmokeInferenceRealization
            .definition

    try ContractProof.identifier(
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

