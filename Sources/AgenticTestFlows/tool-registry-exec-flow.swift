import Agentic
import Primitives
import TestFlows

extension AgenticFlowTesting {
    static func runToolRegistryExecutesWithContext() async throws -> [TestFlowDiagnostic] {
        let preparedIntentID = PreparedIntentIdentifier(
            "prepared-context-test"
        )
        let call = AgentToolCall(
            id: "context-echo-call",
            name: ContextEchoTool.identifier.rawValue,
            input: try JSONToolBridge.encode(
                ContextEchoToolInput(
                    marker: "context-ok"
                )
            )
        )
        let registry = ToolRegistry(
            tools: [
                ContextEchoTool()
            ]
        )

        let result = try await registry.execute(
            call,
            context: .init(
                sessionID: "context-session",
                preparedIntentID: preparedIntentID,
                executionMode: .prepared_intent_replay,
                metadata: [
                    "source": "tool-registry-test"
                ]
            )
        )
        let output = try JSONToolBridge.decode(
            ContextEchoToolOutput.self,
            from: result.output
        )

        try Expect.equal(
            result.toolCallID,
            call.id,
            "registry result forwards tool call id"
        )

        try Expect.equal(
            result.name,
            ContextEchoTool.identifier.rawValue,
            "registry result forwards tool name"
        )

        try Expect.equal(
            output.toolCallID,
            call.id,
            "tool receives tool call id"
        )

        try Expect.equal(
            output.preparedIntentID,
            preparedIntentID.rawValue,
            "tool receives prepared intent id"
        )

        try Expect.equal(
            output.executionMode,
            AgentToolExecutionMode.prepared_intent_replay.rawValue,
            "tool receives execution mode"
        )

        try Expect.equal(
            output.sessionID,
            "context-session",
            "tool receives session id"
        )

        try Expect.equal(
            output.metadataSource,
            "tool-registry-test",
            "tool receives metadata"
        )

        return [
            .field(
                "toolCallID",
                output.toolCallID ?? "<nil>"
            ),
            .field(
                "preparedIntentID",
                output.preparedIntentID ?? "<nil>"
            ),
            .field(
                "executionMode",
                output.executionMode
            )
        ]
    }
}

private struct ContextEchoTool: AgentTool {
    static let identifier: AgentToolIdentifier = "context_echo_tool"

    let identifier: AgentToolIdentifier = Self.identifier
    let description = "Echoes execution context fields."
    let risk: ActionRisk = .observe

    func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        _ = workspace

        let decoded = try JSONToolBridge.decode(
            ContextEchoToolInput.self,
            from: input
        )

        return try JSONToolBridge.encode(
            ContextEchoToolOutput(
                marker: decoded.marker,
                toolCallID: nil,
                preparedIntentID: nil,
                executionMode: AgentToolExecutionMode.host_call.rawValue,
                sessionID: nil,
                metadataSource: nil
            )
        )
    }

    func call(
        input: JSONValue,
        context: AgentToolExecutionContext
    ) async throws -> JSONValue {
        let decoded = try JSONToolBridge.decode(
            ContextEchoToolInput.self,
            from: input
        )

        return try JSONToolBridge.encode(
            ContextEchoToolOutput(
                marker: decoded.marker,
                toolCallID: context.toolCallID,
                preparedIntentID: context.preparedIntentID?.rawValue,
                executionMode: context.executionMode.rawValue,
                sessionID: context.sessionID,
                metadataSource: context.metadata["source"]
            )
        )
    }
}

private struct ContextEchoToolInput: Sendable, Codable, Hashable {
    var marker: String
}

private struct ContextEchoToolOutput: Sendable, Codable, Hashable {
    var marker: String
    var toolCallID: String?
    var preparedIntentID: String?
    var executionMode: String
    var sessionID: String?
    var metadataSource: String?
}
