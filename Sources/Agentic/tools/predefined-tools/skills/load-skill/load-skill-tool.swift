import Primitives

public struct LoadSkillTool: AgentTool {
    public let definition: AgentToolDefinition
    public let registry: SkillRegistry

    public var actionRisk: ActionRisk {
        .observe
    }

    public init(
        registry: SkillRegistry
    ) {
        self.definition = .init(
            name: "load_skill",
            description: "Load the full instructions for one available skill by id or name."
        )
        self.registry = registry
    }

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let decoded = try JSONToolBridge.decode(
            LoadSkillToolInput.self,
            from: input
        )

        let lookup = try lookupValue(
            from: decoded
        )

        return .init(
            toolName: definition.name,
            actionRisk: actionRisk,
            workspaceRoot: workspace?.rootURL.path,
            summary: "Load skill '\(lookup)'.",
            sideEffects: actionRisk.defaultSideEffects
        )
    }

    public func call(
        input: JSONValue,
        workspace _: AgentWorkspace?
    ) async throws -> JSONValue {
        let decoded = try JSONToolBridge.decode(
            LoadSkillToolInput.self,
            from: input
        )

        let lookup = try lookupValue(
            from: decoded
        )
        let skill = try registry.requireSkill(
            matching: lookup
        )

        return try JSONToolBridge.encode(
            LoadSkillToolOutput(
                id: skill.id,
                name: skill.name,
                summary: skill.summary,
                content: skill.contextText,
                metadata: decoded.includeMetadata == true ? skill.metadata : nil
            )
        )
    }
}

private extension LoadSkillTool {
    func lookupValue(
        from input: LoadSkillToolInput
    ) throws -> String {
        let value = input.id ?? input.name
        let trimmed = value?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard let trimmed,
              !trimmed.isEmpty
        else {
            throw SkillToolError.missingSkillIdentifier
        }

        return trimmed
    }
}
