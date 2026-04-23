extension Agentic {
    public struct ToolBootstrapAPI: Sendable {
        public init() {}

        public static func registry(
            tools: [any AgentTool] = [],
            toolSets: [any AgentToolSet] = [],
            toolProviders: [any AgentToolProvider] = []
        ) throws -> ToolRegistry {
            var registry = ToolRegistry()

            try registry.register(tools)

            for toolSet in toolSets {
                try registry.register(toolSet)
            }

            for provider in toolProviders {
                try registry.register(
                    from: provider
                )
            }

            return registry
        }
    }

    public struct SkillBootstrapAPI: Sendable {
        public init() {}

        public static func registry(
            skills: [AgentSkill] = [],
            skillProviders: [any AgentSkillProvider] = []
        ) throws -> SkillRegistry {
            var registry = SkillRegistry()

            try registry.register(skills)

            for provider in skillProviders {
                try registry.register(
                    from: provider
                )
            }

            return registry
        }
    }
}

extension Agentic {
    public static let tool: ToolBootstrapAPI = .init()
    public static let skill: SkillBootstrapAPI = .init()
}
