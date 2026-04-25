import Primitives

public protocol AgentTool: Sendable {
    var identifier: AgentToolIdentifier { get }
    var description: String { get }
    var inputSchema: JSONValue? { get }
    var risk: ActionRisk { get }

    func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight

    func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue
}

public extension AgentTool {
    var inputSchema: JSONValue? {
        nil
    }

    var name: String {
        identifier.rawValue
    }

    var definition: AgentToolDefinition {
        .init(
            identifier: identifier,
            description: description,
            inputSchema: inputSchema
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
}
