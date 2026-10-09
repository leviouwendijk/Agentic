import Agentic
import Foundation
import Primitives
import Schema
import Testing

extension ExecutionTesting {
    static func runToolExecutionTargeting() async throws -> [TestDiagnostic] {
        let registry = try ToolRegistry {
            TargetingTool()
        }

        let descriptor = try Expect.notNil(
            registry.modelFacingDefinition(
                identifiedBy: TargetingTool.definition.identifier
            ),
            "tool is model facing"
        )
        let encoded = try JSONEncoder().encode(descriptor)
        try Expect.equal(
            String(decoding: encoded, as: UTF8.self).contains("\"inputSchema\""),
            true,
            "Descriptor retains its pre-rename Codable key."
        )
        let schema = try Expect.notNil(
            descriptor.input?.valueOrNil.object,
            "tool advertises an object schema"
        )
        let properties = try Expect.notNil(
            schema["properties"]?.valueOrNil.object,
            "model invocation envelope exposes properties"
        )

        try Expect.equal(
            properties["arguments"] != nil,
            true,
            "model invocation carries semantic arguments"
        )
        try Expect.equal(
            properties["execution"] != nil,
            true,
            "model invocation exposes optional execution metadata"
        )

        let call = ToolCall(
            id: "targeted-call",
            tool: TargetingTool.definition.identifier,
            input: .object([
                "arguments": try JSONValue.encoding(
                    TargetingPlaceholderInput(
                        value: "hello"
                    )
                ),
                "execution": .object([
                    "workspace": .object([
                        "subpath": .string("Agentic")
                    ])
                ])
            ])
        )
        let resolved = try registry.invocation(
            for: call
        )

        try Expect.equal(
            resolved.execution?.workspace?.subpath,
            "Agentic",
            "model invocation decodes the requested workspace subpath"
        )
        try Expect.equal(
            try resolved.arguments.value(
                forDotPath: "value"
            ).stringValue,
            "hello",
            "model invocation unwraps semantic arguments"
        )

        let plainCall = ToolCall(
            id: "plain-call",
            tool: TargetingTool.definition.identifier,
            input: .object([
                "arguments": try JSONValue.encoding(
                    TargetingPlaceholderInput(
                        value: "world"
                    )
                ),
            ])
        )
        let plainResolved = try registry.invocation(
            for: plainCall
        )

        try Expect.equal(
            plainResolved.execution,
            nil,
            "omitting execution preserves the current workspace"
        )

        let invoker = ToolInvoker(
            registry: registry,
            policy: .init(
                autonomyMode: .auto_observe
            )
        )

        do {
            _ = try await invoker.invoke(
                resolved,
                context: .init()
            )

            throw TargetingFlowFailure.expectedWorkspaceRequirement
        } catch WorkspaceToolTargetingError.workspaceRequired {
        }

        return [
            .field(
                "schema",
                "arguments+execution"
            ),
            .field(
                "resolvedExecution",
                resolved.execution?.workspace?.subpath ?? "none"
            ),
            .field(
                "targetAuthority",
                "workspace"
            ),
        ]
    }
}

private struct TargetingPlaceholderInput:
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

private struct TargetingTool: Tool {
    typealias Input = TargetingPlaceholderInput
    typealias Output = TargetingPlaceholderInput

    static let definition = ToolDefinition(
        identifier: "targeting",
        purpose: "Workspace-targeting fixture.",
        risk: .observe
    )

    func call(
        _ input: Input,
        in _: ToolContext
    ) async throws -> Output {
        input
    }
}

private enum TargetingFlowFailure: Error {
    case expectedWorkspaceRequirement
}
