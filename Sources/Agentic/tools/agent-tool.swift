import Primitives

public protocol AgentTool: Sendable {
    var identifier: AgentToolIdentifier { get }
    var description: String { get }
    var inputSchema: JSONValue? { get }
    var risk: ActionRisk { get }

    func receipt(
        input: JSONValue,
        output: JSONValue,
        workspace: AgentWorkspace?
    ) -> AgentToolReceipt?

    func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight

    func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue

    func call(
        input: JSONValue,
        context: AgentToolExecutionContext
    ) async throws -> JSONValue
}

public extension AgentTool {
    var inputSchema: JSONValue? {
        nil
    }

    func receipt(
        input _: JSONValue,
        output _: JSONValue,
        workspace _: AgentWorkspace?
    ) -> AgentToolReceipt? {
        nil
    }

    var name: String {
        identifier.rawValue
    }

    var definition: AgentToolDefinition {
        .init(
            identifier: identifier,
            description: description,
            inputSchema: inputSchema,
            risk: risk
        )
    }

    func preflight(
        input _: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        ToolPreflight(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            summary: description,
            sideEffects: risk.defaultSideEffects
        )
    }

    func call(
        input: JSONValue,
        context: AgentToolExecutionContext
    ) async throws -> JSONValue {
        try await call(
            input: input,
            workspace: context.workspace
        )
    }
}
