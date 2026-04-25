import Agentic
import Primitives

struct EchoTool: AgentTool, StaticAgentToolMetadata {
    static let identifier: AgentToolIdentifier = .init(
        "echo_tool"
    )
    static let description = "Echoes a value back to the model."
    static let risk: ActionRisk = .observe

    func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        _ = workspace

        let decoded = try JSONToolBridge.decode(
            EchoToolInput.self,
            from: input
        )

        return try JSONToolBridge.encode(
            EchoToolOutput(
                text: decoded.text
            )
        )
    }
}

struct EchoToolInput: Sendable, Codable, Hashable {
    var text: String
}

struct EchoToolOutput: Sendable, Codable, Hashable {
    var text: String
}
