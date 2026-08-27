extension Agentic {
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
    public static let skill: SkillBootstrapAPI = .init()
}
