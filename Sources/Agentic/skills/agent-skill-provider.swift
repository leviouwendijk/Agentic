public protocol AgentSkillProvider: Sendable {
    func registerSkills(
        into registry: inout SkillRegistry
    ) throws
}
