public extension SkillRegistry {
    init(
        @AgentSkillBuilder _ content: () throws -> [AgentSkillRegistration]
    ) throws {
        self.init()

        try register(
            content
        )
    }

    mutating func register(
        @AgentSkillBuilder _ content: () throws -> [AgentSkillRegistration]
    ) throws {
        let registrations = try content()

        for registration in registrations {
            try registration.apply(
                into: &self
            )
        }
    }
}

public func skills(
    @AgentSkillBuilder _ content: () throws -> [AgentSkillRegistration]
) rethrows -> [AgentSkillRegistration] {
    try content()
}
