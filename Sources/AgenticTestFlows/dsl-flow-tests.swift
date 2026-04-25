import Agentic
import Primitives
import TestFlows

extension AgenticFlowTesting {
    static func runDSLTypedCall() async throws -> [TestFlowDiagnostic] {
        let declaration = tool("dsl_echo") {
            description("Echoes a value through the declaration DSL.")
            risk(.observe)

            call(
                input: EchoToolInput.self,
                output: EchoToolOutput.self
            ) { input in
                EchoToolOutput(
                    text: input.text
                )
            }
        }

        let tool = try declaration.makeTool()
        let input = try JSONToolBridge.encode(
            EchoToolInput(
                text: "typed"
            )
        )

        let output = try await tool.call(
            input: input,
            workspace: AgentWorkspace?.none
        )

        let decoded = try JSONToolBridge.decode(
            EchoToolOutput.self,
            from: output
        )

        try expect(
            decoded.text == "typed",
            "typed DSL call returned '\(decoded.text)'"
        )

        return [
            .field(
                "response",
                decoded.text
            )
        ]
    }

    static func runDSLContextualTypedCall() async throws -> [TestFlowDiagnostic] {
        let declaration = tool("dsl_context_echo") {
            description("Uses AgentToolContext through the declaration DSL.")
            risk(.observe)

            call(
                input: EchoToolInput.self,
                output: EchoToolOutput.self
            ) { input, context in
                EchoToolOutput(
                    text: context.workspace == nil
                        ? "\(input.text):no-workspace"
                        : "\(input.text):workspace"
                )
            }
        }

        let tool = try declaration.makeTool()
        let input = try JSONToolBridge.encode(
            EchoToolInput(
                text: "context"
            )
        )

        let output = try await tool.call(
            input: input,
            workspace: AgentWorkspace?.none
        )

        let decoded = try JSONToolBridge.decode(
            EchoToolOutput.self,
            from: output
        )

        try expect(
            decoded.text == "context:no-workspace",
            "contextual DSL call returned '\(decoded.text)'"
        )

        return [
            .field(
                "response",
                decoded.text
            )
        ]
    }

    static func runDSLEffectCall() async throws -> [TestFlowDiagnostic] {
        let counter = DSLFlowCounter()

        let declaration = tool("dsl_effect") {
            description("Runs a typed effect through the declaration DSL.")
            risk(.boundedmutate)

            effect(
                input: EchoToolInput.self
            ) { input in
                await counter.record(
                    input.text
                )
            }
        }

        let tool = try declaration.makeTool()
        let input = try JSONToolBridge.encode(
            EchoToolInput(
                text: "effect"
            )
        )

        _ = try await tool.call(
            input: input,
            workspace: AgentWorkspace?.none
        )

        let recorded = await counter.value()

        try expect(
            recorded == "effect",
            "effect DSL call recorded '\(recorded)'"
        )

        return [
            .field(
                "recorded",
                recorded
            )
        ]
    }

    static func runDSLMissingCallThrows() async throws -> [TestFlowDiagnostic] {
        let declaration = tool("dsl_missing_call") {
            description("This declaration intentionally has no call handler.")
            risk(.observe)
        }

        do {
            _ = try declaration.makeTool()

            throw FlowTestError.unexpectedResult(
                "missing-call DSL declaration unexpectedly built a tool"
            )
        } catch AgentToolDeclarationError.missingCall(let identifier) {
            try expect(
                identifier == "dsl_missing_call",
                "missing call error referenced '\(identifier)'"
            )

            return [
                .field(
                    "error",
                    "missing_call"
                ),
                .field(
                    "identifier",
                    identifier
                )
            ]
        }
    }

    static func runDSLRegistryAcceptsMixedInputs() async throws -> [TestFlowDiagnostic] {
        let declaration = tool("dsl_registry_declaration") {
            description("Registered from a declaration.")
            risk(.observe)

            call(
                input: EchoToolInput.self,
                output: EchoToolOutput.self
            ) { input in
                EchoToolOutput(
                    text: input.text
                )
            }
        }

        let registry = try Agentic.tool.registry {
            declaration
            DSLConcreteTool()
            DSLToolSet()
        }

        try expect(
            registry.count == 3,
            "DSL registry expected 3 tools, found \(registry.count)"
        )

        try expect(
            registry.tool(named: "dsl_registry_declaration") != nil,
            "DSL registry missing declaration tool"
        )

        try expect(
            registry.tool(named: "dsl_concrete_tool") != nil,
            "DSL registry missing concrete tool"
        )

        try expect(
            registry.tool(named: "dsl_tool_set_tool") != nil,
            "DSL registry missing tool-set tool"
        )

        return [
            .field(
                "registry_count",
                "\(registry.count)"
            ),
            .field(
                "tools",
                "dsl_registry_declaration,dsl_concrete_tool,dsl_tool_set_tool"
            )
        ]
    }
}

private actor DSLFlowCounter {
    private var recorded = ""

    func record(
        _ value: String
    ) {
        recorded = value
    }

    func value() -> String {
        recorded
    }
}

private struct DSLConcreteTool: AgentTool {
    let identifier: AgentToolIdentifier = "dsl_concrete_tool"
    let description = "Concrete DSL registry test tool."
    let risk: ActionRisk = .observe

    func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        _ = input
        _ = workspace

        return try JSONToolBridge.encode(
            EchoToolOutput(
                text: "concrete"
            )
        )
    }
}

private struct DSLToolSet: AgentToolSet {
    func register(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register(
            DSLToolSetTool()
        )
    }
}

private struct DSLToolSetTool: AgentTool {
    let identifier: AgentToolIdentifier = "dsl_tool_set_tool"
    let description = "Tool-set DSL registry test tool."
    let risk: ActionRisk = .observe

    func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        _ = input
        _ = workspace

        return try JSONToolBridge.encode(
            EchoToolOutput(
                text: "tool-set"
            )
        )
    }
}

private func expect(
    _ condition: @autoclosure () -> Bool,
    _ message: String
) throws {
    guard condition() else {
        throw FlowTestError.unexpectedResult(
            message
        )
    }
}
