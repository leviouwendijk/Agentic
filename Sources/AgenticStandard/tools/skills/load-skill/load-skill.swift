import Agentic
import Workspace
import Primitives

public struct LoadSkill: Tool {
    public typealias Input = LoadSkillInput
    public typealias Output = LoadSkillOutput

    public static let identifier: ToolIdentifier = "load_skill"
    public static let description = "Load the full instructions for one available skill by id or name."
    public static let risk: ActionRisk = .observe
    public static let definition = ToolDefinition(
        identifier: identifier,
        purpose: description,
        risk: risk
    )

    public var identifier: ToolIdentifier {
        Self.identifier
    }

    public var description: String {
        Self.description
    }

    public var risk: ActionRisk {
        Self.risk
    }

    public let registry: SkillRegistry

    public init(
        registry: SkillRegistry
    ) {
        self.registry = registry
    }

    public func preflight(
        _ input: Input,
        workspace _: WorkspaceContext?
    ) async throws -> ToolPreflight {

        let lookup = try lookupValue(
            from: input
        )

        return .init(
            tool: Self.definition.identifier,
            risk: Self.definition.risk,
            summary: "Load skill '\(lookup)'.",
            sideEffects: Self.definition.risk.defaultSideEffects
        )
    }

    public func call(
        _ input: Input,
        workspace _: WorkspaceContext?
    ) async throws -> Output {

        let lookup = try lookupValue(
            from: input
        )
        let skill = try registry.requireSkill(
            matching: lookup
        )

        return LoadSkillOutput(
                id: skill.identifier.rawValue,
                name: skill.name,
                summary: skill.summary,
                content: skill.contextText,
                metadata: input.includeMetadata == true ? skill.metadata : nil
            )
    }
}

private extension LoadSkill {
    func lookupValue(
        from input: LoadSkillInput
    ) throws -> String {
        let value = input.id ?? input.name
        let trimmed = value?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard let trimmed,
              !trimmed.isEmpty
        else {
            throw SkillError.missingSkillIdentifier
        }

        return trimmed
    }
}