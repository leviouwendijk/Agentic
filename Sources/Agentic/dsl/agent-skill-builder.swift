public struct AgentSkillRegistration: Sendable {
    private let applyHandler: @Sendable (
        inout SkillRegistry
    ) throws -> Void

    public init(
        _ applyHandler: @escaping @Sendable (
            inout SkillRegistry
        ) throws -> Void
    ) {
        self.applyHandler = applyHandler
    }

    public func apply(
        into registry: inout SkillRegistry
    ) throws {
        try applyHandler(
            &registry
        )
    }
}

public extension AgentSkillRegistration {
    static func skill(
        _ skill: AgentSkill
    ) -> Self {
        .init { registry in
            try registry.register(
                skill
            )
        }
    }

    static func skill(
        _ draft: AgentSkillDraft
    ) -> Self {
        .skill(
            draft.build()
        )
    }

    static func provider(
        _ provider: any AgentSkillProvider
    ) -> Self {
        .init { registry in
            try registry.register(
                from: provider
            )
        }
    }
}

@resultBuilder
public enum AgentSkillBuilder {
    public static func buildBlock(
        _ components: [AgentSkillRegistration]...
    ) -> [AgentSkillRegistration] {
        components.flatMap {
            $0
        }
    }

    public static func buildExpression(
        _ expression: AgentSkill
    ) -> [AgentSkillRegistration] {
        [
            .skill(expression)
        ]
    }

    public static func buildExpression(
        _ expression: AgentSkillDraft
    ) -> [AgentSkillRegistration] {
        [
            .skill(expression)
        ]
    }

    public static func buildExpression(
        _ expression: any AgentSkillProvider
    ) -> [AgentSkillRegistration] {
        [
            .provider(expression)
        ]
    }

    public static func buildExpression(
        _ expression: AgentSkillRegistration
    ) -> [AgentSkillRegistration] {
        [
            expression
        ]
    }

    public static func buildExpression(
        _ expression: [AgentSkillRegistration]
    ) -> [AgentSkillRegistration] {
        expression
    }

    public static func buildOptional(
        _ component: [AgentSkillRegistration]?
    ) -> [AgentSkillRegistration] {
        component ?? []
    }

    public static func buildEither(
        first component: [AgentSkillRegistration]
    ) -> [AgentSkillRegistration] {
        component
    }

    public static func buildEither(
        second component: [AgentSkillRegistration]
    ) -> [AgentSkillRegistration] {
        component
    }

    public static func buildArray(
        _ components: [[AgentSkillRegistration]]
    ) -> [AgentSkillRegistration] {
        components.flatMap {
            $0
        }
    }

    public static func buildLimitedAvailability(
        _ component: [AgentSkillRegistration]
    ) -> [AgentSkillRegistration] {
        component
    }
}
