public struct CoreSkillProvider: AgentSkillProvider {
    public init() {}

    public func registerSkills(
        into registry: inout SkillRegistry
    ) throws {
        try registry.register(
            [
                Self.safeFileEditing,
                Self.contextPacking,
                Self.debuggingLoop,
                Self.refactoringPlan,
                Self.handoffSummary
            ]
        )
    }
}
