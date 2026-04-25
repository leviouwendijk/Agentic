extension Agentic {
    public struct ToolBootstrapAPI: Sendable {
        public init() {}

        public func registry(
            tools: [any AgentTool] = [],
            toolSets: [any AgentToolSet] = [],
            toolProviders: [any AgentToolProvider] = []
        ) throws -> ToolRegistry {
            var registry = ToolRegistry()

            try registry.register(
                tools
            )

            for toolSet in toolSets {
                try registry.register(
                    toolSet
                )
            }

            for provider in toolProviders {
                try registry.register(
                    from: provider
                )
            }

            return registry
        }

        public func registry(
            @AgentToolBuilder _ content: () throws -> [AgentToolRegistration]
        ) throws -> ToolRegistry {
            var registry = ToolRegistry()

            try registry.register(
                content
            )

            return registry
        }

        public static func registry(
            tools: [any AgentTool] = [],
            toolSets: [any AgentToolSet] = [],
            toolProviders: [any AgentToolProvider] = []
        ) throws -> ToolRegistry {
            try Self().registry(
                tools: tools,
                toolSets: toolSets,
                toolProviders: toolProviders
            )
        }

        public static func registry(
            @AgentToolBuilder _ content: () throws -> [AgentToolRegistration]
        ) throws -> ToolRegistry {
            try Self().registry(
                content
            )
        }
    }

    public struct SkillBootstrapAPI: Sendable {
        public init() {}

        public func registry(
            skills: [AgentSkill] = [],
            skillProviders: [any AgentSkillProvider] = []
        ) throws -> SkillRegistry {
            var registry = SkillRegistry()

            try registry.register(
                skills
            )

            for provider in skillProviders {
                try registry.register(
                    from: provider
                )
            }

            return registry
        }

        public func registry(
            @AgentSkillBuilder _ content: () throws -> [AgentSkillRegistration]
        ) throws -> SkillRegistry {
            var registry = SkillRegistry()

            try registry.register(
                content
            )

            return registry
        }

        public static func registry(
            skills: [AgentSkill] = [],
            skillProviders: [any AgentSkillProvider] = []
        ) throws -> SkillRegistry {
            try Self().registry(
                skills: skills,
                skillProviders: skillProviders
            )
        }

        public static func registry(
            @AgentSkillBuilder _ content: () throws -> [AgentSkillRegistration]
        ) throws -> SkillRegistry {
            try Self().registry(
                content
            )
        }
    }
}

extension Agentic {
    public static let tool: ToolBootstrapAPI = .init()
    public static let skill: SkillBootstrapAPI = .init()
}
