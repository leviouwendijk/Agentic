import Primitives

public protocol AgentTool: Sendable {
    var definition: AgentToolDefinition { get }
    var actionRisk: ActionRisk { get }

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
    func preflight(
        input _: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        ToolPreflight(
            toolName: definition.name,
            actionRisk: actionRisk,
            workspaceRoot: workspace?.rootURL.path,
            summary: definition.description,
            sideEffects: actionRisk.defaultSideEffects
        )
    }
}
