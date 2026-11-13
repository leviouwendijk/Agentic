extension Agentic {
    public struct ToolBootstrapAPI: Sendable {
        public init() {}

        public func registry(
            @AgentToolBuilder
            _ content: () throws -> [ToolBinding]
        ) throws -> ToolRegistry {
            var registry = ToolRegistry()

            try registry.register(
                content
            )

            return registry
        }

        public static func registry(
            @AgentToolBuilder
            _ content: () throws -> [ToolBinding]
        ) throws -> ToolRegistry {
            try Self().registry(
                content
            )
        }
    }
}

extension Agentic {
    public static let tool: ToolBootstrapAPI = .init()
}
