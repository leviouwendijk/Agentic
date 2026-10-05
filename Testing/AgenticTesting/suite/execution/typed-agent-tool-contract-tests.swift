import Agentic
import Foundation
import Primitives
import Schema
import Testing

extension ExecutionTesting {
    static func runTypedAgentToolContract() async throws -> [TestDiagnostic] {
        let probe = TypedAgentToolContractProbe()
        let tool = TypedAgentToolContractTool(
            probe: probe
        )
        var registry = ToolRegistry()

        try registry.register(
            tool
        )

        let semanticInput = try JSONValue.encoding(
            TypedAgentToolContractInput(
                value: "hello"
            )
        )
        let modelCall = ToolCall(
            id: "typed-tool-contract-model-call",
            tool: tool.identifier,
            input: .object([
                "arguments": semanticInput,
            ])
        )
        let parsed = try registry.invocation(
            for: modelCall
        )

        try Expect.equal(
            parsed.tool,
            tool.identifier,
            "resolution preserves the concrete tool identity"
        )
        try Expect.equal(
            parsed.execution,
            nil,
            "omitting invocation execution preserves the current workspace"
        )
        try Expect.equal(
            parsed.arguments,
            semanticInput,
            "model invocation unwraps the semantic arguments"
        )

        let call = ToolCall(
            id: "typed-tool-contract-call",
            tool: tool.identifier,
            input: semanticInput
        )

        let preflight = try await registry.preflight(
            call,
            workspace: nil
        )

        try Expect.contains(
            preflight.summary,
            "hello",
            "typed preflight receives decoded Input"
        )

        let result = try await registry.execute(
            call,
            workspace: nil
        )
        let output = try result.result.output.decode(
            TypedAgentToolContractOutput.self
        )
        let projection = try Expect.notNil(
            result.result.projection,
            "typed process supplies the result projection"
        )

        try Expect.equal(
            output.value,
            "HELLO",
            "typed call returns typed Output through JSON erasure"
        )
        try Expect.equal(
            projection.summary,
            Optional("input:hello output:HELLO"),
            "process sees both typed Input and typed Output"
        )
        try Expect.equal(
            await probe.preflightValues(),
            [
                "hello",
            ],
            "typed preflight crosses the erasure boundary once"
        )
        try Expect.equal(
            await probe.callValues(),
            [
                "hello",
            ],
            "stateful tool dependencies survive registration erasure"
        )

        return [
            .field(
                "output",
                output.value
            ),
            .field(
                "projection",
                projection.status
            ),
        ]
    }
}

private struct TypedAgentToolContractInput:
    Sendable,
    Codable,
    Hashable,
    JSONSchemaProviding
{
    let value: String

    static var jsonschema: JSONSchema {
        JSONSchema.object {
            JSONSchema.string(
                "value",
                required: true
            )
        }
    }
}

private struct TypedAgentToolContractOutput:
    Sendable,
    Codable,
    Hashable,
    JSONSchemaProviding
{
    let value: String

    static var jsonschema: JSONSchema {
        .any
    }
}

private actor TypedAgentToolContractProbe {
    private var preflights: [String] = []
    private var calls: [String] = []

    func recordPreflight(
        _ value: String
    ) {
        preflights.append(
            value
        )
    }

    func recordCall(
        _ value: String
    ) {
        calls.append(
            value
        )
    }

    func preflightValues() -> [String] {
        preflights
    }

    func callValues() -> [String] {
        calls
    }
}

private struct TypedAgentToolContractTool: Tool {
    typealias Input = TypedAgentToolContractInput
    typealias Output = TypedAgentToolContractOutput

    static let definition = ToolDefinition(
        identifier: "typed_tool_contract",
        purpose:
            "Exercise typed Tool registration and execution.",
        risk: .observe
    )

    let probe: TypedAgentToolContractProbe

    func preflight(
        _ input: Input,
        in _: ToolContext
    ) async throws -> ToolPreflight {
        await probe.recordPreflight(
            input.value
        )

        return ToolPreflight(
            tool: Self.definition.identifier,
            risk: Self.definition.risk,
            summary:
                "Typed preflight for \(input.value).",
            sideEffects: []
        )
    }

    func call(
        _ input: Input,
        in _: ToolContext
    ) async throws -> Output {
        await probe.recordCall(
            input.value
        )

        return Output(
            value: input.value.uppercased()
        )
    }

    func process(
        _ output: Output,
        input: Input
    ) -> ToolCall.ResultProjection? {
        .init(
            status: "completed",
            summary:
                "input:\(input.value) output:\(output.value)",
            facts: [
                .init(
                    label: "input",
                    value: input.value
                ),
                .init(
                    label: "output",
                    value: output.value
                ),
            ]
        )
    }
}
