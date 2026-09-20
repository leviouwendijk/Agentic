import Agentic
import Workspace
import Primitives

public struct ListSkills: Tool {
    public typealias Input = ListSkillsInput
    public typealias Output = ListSkillsOutput

    public static let identifier: ToolIdentifier = "list_skills"
    public static let description = "List available skills and their summaries."
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

        let query = input.query?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let summary = if let query,
                         !query.isEmpty {
            "List available skills matching '\(query)'."
        } else {
            "List all available skills."
        }

        return .init(
            tool: Self.definition.identifier,
            risk: Self.definition.risk,
            summary: summary,
            sideEffects: Self.definition.risk.defaultSideEffects
        )
    }

    public func call(
        _ input: Input,
        workspace _: WorkspaceContext?
    ) async throws -> Output {

        let includeBody = input.includeBody ?? false
        let query = input.query?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let selected = registry.skills_sorted.filter { skill in
            guard let query,
                  !query.isEmpty
            else {
                return true
            }

            let normalized = query.lowercased()

            return skill.identifier.rawValue.lowercased().contains(normalized)
                || skill.name.lowercased().contains(normalized)
                || skill.summary.lowercased().contains(normalized)
        }

        let skills = selected.map { skill in
            ListedSkill(
                id: skill.identifier.rawValue,
                name: skill.name,
                summary: skill.summary,
                metadata: skill.metadata,
                body: includeBody ? skill.body : nil
            )
        }

        return ListSkillsOutput(
                skills: skills,
                count: skills.count,
                catalog: selected
                    .map { skill in
                        skill.descriptionLine
                    }
                    .joined(separator: "\n")
            )
    }
}