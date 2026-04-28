public extension ModeSelection {
    func apply(
        tools sourceTools: ToolRegistry,
        skills sourceSkills: SkillRegistry = .init(),
        metadata additionalMetadata: [String: String] = [:]
    ) throws -> ModeRuntimeApplication {
        let selectedTools = try sourceTools.selecting(
            exposedToolIdentifiers
        )
        let selectedSkills = try sourceSkills.selecting(
            loadedSkillIdentifiers
        )
        let metadata = self.metadata.merging(
            additionalMetadata
        ) { _, new in
            new
        }

        return .init(
            selection: self,
            configuration: configuration,
            routePolicy: routePolicy,
            toolRegistry: selectedTools,
            skillRegistry: selectedSkills.registry,
            loadedSkills: selectedSkills.loadedSkills,
            missingSkillIdentifiers: selectedSkills.missingIdentifiers,
            metadata: metadata
        )
    }
}
