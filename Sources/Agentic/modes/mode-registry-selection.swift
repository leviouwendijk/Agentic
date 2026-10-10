public struct ModeSkillSelection: Sendable {
    public var registry: SkillRegistry
    public var loadedSkills: [AgentSkill]
    public var missingIdentifiers: [AgentSkillIdentifier]

    /// Preserve the selected order, rather than dictionary/registry order.
    public var instructions: Instructions {
        Instructions(loadedSkills.map { .instruction($0.instruction) })
    }

    public init(
        registry: SkillRegistry,
        loadedSkills: [AgentSkill],
        missingIdentifiers: [AgentSkillIdentifier]
    ) {
        self.registry = registry
        self.loadedSkills = loadedSkills
        self.missingIdentifiers = missingIdentifiers
    }
}

public extension SkillRegistry {
    func selecting(
        _ identifiers: [AgentSkillIdentifier]
    ) throws -> ModeSkillSelection {
        var selected = SkillRegistry()
        var loaded: [AgentSkill] = []
        var missing: [AgentSkillIdentifier] = []
        var seen = Set<AgentSkillIdentifier>()

        for identifier in identifiers {
            guard seen.insert(identifier).inserted else {
                continue
            }

            guard let skill = skill(
                identifiedBy: identifier
            ) else {
                missing.append(
                    identifier
                )
                continue
            }

            try selected.register(
                skill
            )
            loaded.append(
                skill
            )
        }

        return .init(
            registry: selected,
            loadedSkills: loaded,
            missingIdentifiers: missing
        )
    }
}
