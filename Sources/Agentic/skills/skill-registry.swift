public struct SkillRegistry: Sendable {
    private var skills: [String: AgentSkill]

    public init(
        skills: [AgentSkill] = []
    ) {
        self.skills = Dictionary(
            uniqueKeysWithValues: skills.map { skill in
                (skill.id, skill)
            }
        )
    }

    public var skills_sorted: [AgentSkill] {
        skills.values.sorted { lhs, rhs in
            lhs.name < rhs.name
        }
    }

    public var isEmpty: Bool {
        skills.isEmpty
    }

    public var count: Int {
        skills.count
    }

    public mutating func register(
        _ skill: AgentSkill
    ) throws {
        guard skills[skill.id] == nil else {
            throw SkillRegistryError.duplicateSkill(skill.id)
        }

        skills[skill.id] = skill
    }

    public mutating func register(
        _ skills: [AgentSkill]
    ) throws {
        for skill in skills {
            try register(skill)
        }
    }

    public mutating func register(
        from provider: any AgentSkillProvider
    ) throws {
        try provider.registerSkills(
            into: &self
        )
    }

    public func skill(
        id: String
    ) -> AgentSkill? {
        skills[id]
    }

    public func skill(
        named name: String
    ) -> AgentSkill? {
        skills.values.first { skill in
            skill.name == name
        }
    }
}
