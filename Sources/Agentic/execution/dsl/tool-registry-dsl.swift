public extension ToolRegistry {
    init(
        @AgentToolBuilder _ content: () throws -> [ToolBinding]
    ) throws {
        self.init()
        try register(content)
    }

    mutating func register(
        @AgentToolBuilder _ content: () throws -> [ToolBinding]
    ) throws {
        for binding in try content() {
            try register(binding)
        }
    }
}

public func tools(
    @AgentToolBuilder _ content: () throws -> [ToolBinding]
) rethrows -> [ToolBinding] {
    try content()
}
