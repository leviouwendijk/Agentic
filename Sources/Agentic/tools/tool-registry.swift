public struct ToolRegistry: Sendable {
    private let toolsByName: [String: any AgentTool]

    public init(
        tools: [any AgentTool] = []
    ) {
        self.toolsByName = Dictionary(
            uniqueKeysWithValues: tools.map { tool in
                (tool.definition.name, tool)
            }
        )
    }

    public var definitions: [AgentToolDefinition] {
        toolsByName.values.map(\.definition).sorted { lhs, rhs in
            lhs.name < rhs.name
        }
    }

    public func tool(
        named name: String
    ) -> (any AgentTool)? {
        toolsByName[name]
    }

    public func preflight(
        _ toolCall: AgentToolCall,
        workspace: AgentWorkspace? = nil
    ) async throws -> ToolPreflight {
        guard let tool = toolsByName[toolCall.name] else {
            throw ToolDispatchError.unknownTool(toolCall.name)
        }

        return try await tool.preflight(
            input: toolCall.input,
            workspace: workspace
        )
    }

    public func call(
        _ toolCall: AgentToolCall,
        workspace: AgentWorkspace? = nil
    ) async throws -> AgentToolResult {
        guard let tool = toolsByName[toolCall.name] else {
            throw ToolDispatchError.unknownTool(toolCall.name)
        }

        let output = try await tool.call(
            input: toolCall.input,
            workspace: workspace
        )

        return AgentToolResult(
            toolCallID: toolCall.id,
            name: toolCall.name,
            output: output
        )
    }
}
