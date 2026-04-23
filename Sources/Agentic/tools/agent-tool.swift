import Primitives

public protocol AgentTool: Sendable {
    static var identifier: AgentToolIdentifier { get }
    static var description: String { get }
    static var inputSchema: JSONValue? { get }
    static var risk: ActionRisk { get }

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
    static var inputSchema: JSONValue? {
        nil
    }

    var identifier: AgentToolIdentifier {
        Self.identifier
    }

    var description: String {
        Self.description
    }

    var inputSchema: JSONValue? {
        Self.inputSchema
    }

    var risk: ActionRisk {
        Self.risk
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
