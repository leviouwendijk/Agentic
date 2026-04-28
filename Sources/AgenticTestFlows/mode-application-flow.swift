import Agentic
import TestFlows

extension AgenticFlowTesting {
    static func runModeApplicationFiltersCoderTools() async throws -> [TestFlowDiagnostic] {
        let selection = try ModeCatalog.standard.selection(
            .coder
        )
        let sourceTools = try Agentic.tool.registry(
            toolSets: [
                CoreToolSet()
            ]
        )
        let application = try selection.apply(
            tools: sourceTools
        )
        let tools = application.toolDefinitions.map(\.name).sorted()

        try Expect.equal(
            application.routePolicy.purpose,
            .coder,
            "mode application route purpose"
        )

        try Expect.equal(
            application.configuration.autonomyMode,
            selection.configuration.autonomyMode,
            "mode application configuration"
        )

        try Expect.equal(
            tools,
            [
                "mutate_files",
                "read_file",
                "scan_paths"
            ],
            "mode application filtered coder tools"
        )

        return [
            .field(
                "mode",
                application.modeID.rawValue
            ),
            .field(
                "purpose",
                application.routePolicy.purpose.rawValue
            ),
            .field(
                "tools",
                tools.joined(separator: ",")
            )
        ]
    }

    static func runModeApplicationRejectsMissingTool() async throws -> [TestFlowDiagnostic] {
        let selection = try ModeCatalog.standard.selection(
            .coder
        )

        do {
            _ = try selection.apply(
                tools: ToolRegistry()
            )

            throw TestFlowAssertionFailure(
                label: "mode application rejects missing tool",
                message: "Expected mode application to reject missing tools."
            )
        } catch ModeApplicationError.missingTool(let identifier) {
            return [
                .field(
                    "missingTool",
                    identifier
                )
            ]
        }
    }

    static func runModeApplicationReportsMissingSkills() async throws -> [TestFlowDiagnostic] {
        let selection = try ModeCatalog.standard.selection(
            .coder
        )
        let sourceTools = try Agentic.tool.registry(
            toolSets: [
                CoreToolSet()
            ]
        )
        let application = try selection.apply(
            tools: sourceTools,
            skills: SkillRegistry()
        )

        try Expect.true(
            !application.missingSkillIdentifiers.isEmpty,
            "mode application reports missing skills"
        )

        try Expect.equal(
            application.loadedSkills.isEmpty,
            true,
            "mode application does not load absent skills"
        )

        return [
            .field(
                "missingSkills",
                application.missingSkillIdentifiers.map(\.rawValue).joined(separator: ",")
            )
        ]
    }

    static func runModeApplicationLoadsAvailableSkills() async throws -> [TestFlowDiagnostic] {
        let selection = try ModeCatalog.standard.selection(
            .coder
        )
        let sourceTools = try Agentic.tool.registry(
            toolSets: [
                CoreToolSet()
            ]
        )

        let skill = AgentSkill(
            identifier: "safe-file-editing",
            name: "Safe file editing",
            summary: "Edit safely.",
            body: "Read before writing."
        )
        var skills = SkillRegistry()
        try skills.register(
            skill
        )

        let application = try selection.apply(
            tools: sourceTools,
            skills: skills
        )

        try Expect.equal(
            application.loadedSkills.map(\.identifier),
            [
                "safe-file-editing"
            ],
            "mode application loaded available skill"
        )

        try Expect.true(
            application.missingSkillIdentifiers.contains(
                "context-packing"
            ),
            "mode application still reports other missing skills"
        )

        return [
            .field(
                "loadedSkills",
                application.loadedSkills.map(\.identifier.rawValue).joined(separator: ",")
            ),
            .field(
                "missingSkills",
                application.missingSkillIdentifiers.map(\.rawValue).joined(separator: ",")
            )
        ]
    }
}
