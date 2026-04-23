public struct SkillRegistry: Sendable {
    private var skills: [AgentSkillIdentifier: AgentSkill]

    public init(
        skills: [AgentSkill] = []
    ) {
        self.skills = Dictionary(
            uniqueKeysWithValues: skills.map { skill in
                (skill.identifier, skill)
            }
        )
    }

    public var skills_sorted: [AgentSkill] {
        skills.values.sorted { lhs, rhs in
            if lhs.name == rhs.name {
                return lhs.identifier.rawValue < rhs.identifier.rawValue
            }

            return lhs.name < rhs.name
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
        guard skills[skill.identifier] == nil else {
            throw SkillRegistryError.duplicateSkill(
                skill.identifier.rawValue
            )
        }

        skills[skill.identifier] = skill
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
        identifiedBy identifier: AgentSkillIdentifier
    ) -> AgentSkill? {
        skills[identifier]
    }

    public func skill(
        id: String
    ) -> AgentSkill? {
        skill(
            identifiedBy: .init(id)
        )
    }

    public func skill(
        named name: String
    ) -> AgentSkill? {
        skills.values.first { skill in
            skill.name == name
        }
    }

    public func skill(
        matching value: String
    ) -> AgentSkill? {
        if let exact = skill(id: value) {
            return exact
        }

        if let exact = skill(named: value) {
            return exact
        }

        let normalized = value.lowercased()

        return skills.values.first { skill in
            skill.identifier.rawValue.lowercased() == normalized
                || skill.name.lowercased() == normalized
        }
    }

    public func requireSkill(
        matching value: String
    ) throws -> AgentSkill {
        guard let skill = skill(matching: value) else {
            throw SkillRegistryError.unknownSkill(value)
        }

        return skill
    }

    public func descriptions() -> String {
        skills_sorted
            .map { skill in
                skill.descriptionLine
            }
            .joined(separator: "\n")
    }

    public func promptCatalog(
        title: String = "Skills available:"
    ) -> String {
        guard !isEmpty else {
            return "\(title)\n- none"
        }

        return "\(title)\n\(descriptions())"
    }
}
