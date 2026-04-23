import Primitives

public struct ListSkillsTool: AgentTool {
    public let definition: AgentToolDefinition
    public let registry: SkillRegistry

    public var actionRisk: ActionRisk {
        .observe
    }

    public init(
        registry: SkillRegistry
    ) {
        self.definition = .init(
            name: "list_skills",
            description: "List available skills and their summaries."
        )
        self.registry = registry
    }

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let decoded = try JSONToolBridge.decode(
            ListSkillsToolInput.self,
            from: input
        )

        let query = decoded.query?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let summary = if let query,
                         !query.isEmpty {
            "List available skills matching '\(query)'."
        } else {
            "List all available skills."
        }

        return .init(
            toolName: definition.name,
            actionRisk: actionRisk,
            workspaceRoot: workspace?.rootURL.path,
            summary: summary,
            sideEffects: actionRisk.defaultSideEffects
        )
    }

    public func call(
        input: JSONValue,
        workspace _: AgentWorkspace?
    ) async throws -> JSONValue {
        let decoded = try JSONToolBridge.decode(
            ListSkillsToolInput.self,
            from: input
        )

        let includeBody = decoded.includeBody ?? false
        let query = decoded.query?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let selected = registry.skills_sorted.filter { skill in
            guard let query,
                  !query.isEmpty
            else {
                return true
            }

            let normalized = query.lowercased()

            return skill.id.lowercased().contains(normalized)
                || skill.name.lowercased().contains(normalized)
                || skill.summary.lowercased().contains(normalized)
        }

        let skills = selected.map { skill in
            ListedSkill(
                id: skill.id,
                name: skill.name,
                summary: skill.summary,
                metadata: skill.metadata,
                body: includeBody ? skill.body : nil
            )
        }

        return try JSONToolBridge.encode(
            ListSkillsToolOutput(
                skills: skills,
                count: skills.count,
                catalog: selected
                    .map(\.descriptionLine)
                    .joined(separator: "\n")
            )
        )
    }
}
