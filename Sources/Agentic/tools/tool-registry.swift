public struct ToolRegistry: Sendable {
    private var tools: [String: any AgentTool]

    public init(
        tools: [any AgentTool] = []
    ) {
        self.tools = Dictionary(
            uniqueKeysWithValues: tools.map { tool in
                (tool.definition.name, tool)
            }
        )
    }

    public var definitions: [AgentToolDefinition] {
        tools.values.map(\.definition).sorted { lhs, rhs in
            lhs.name < rhs.name
        }
    }

    public var isEmpty: Bool {
        tools.isEmpty
    }

    public var count: Int {
        tools.count
    }

    public mutating func register(
        _ tool: any AgentTool
    ) throws {
        let name = tool.definition.name

        guard tools[name] == nil else {
            throw ToolRegistryError.duplicateTool(name)
        }

        tools[name] = tool
    }

    public mutating func register(
        _ tools: [any AgentTool]
    ) throws {
        for tool in tools {
            try register(tool)
        }
    }

    public mutating func register(
        _ toolSet: any AgentToolSet
    ) throws {
        try toolSet.register(
            into: &self
        )
    }

    public mutating func register(
        from provider: any AgentToolProvider
    ) throws {
        try provider.registerTools(
            into: &self
        )
    }

    public func tool(
        named name: String
    ) -> (any AgentTool)? {
        tools[name]
    }

    public func preflight(
        _ toolCall: AgentToolCall,
        workspace: AgentWorkspace? = nil
    ) async throws -> ToolPreflight {
        guard let tool = tools[toolCall.name] else {
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
        guard let tool = tools[toolCall.name] else {
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
