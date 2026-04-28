import Agentic
import TestFlows

extension AgenticFlowTesting {
    static func runModeApplicationComposeLoadedSkillContext() async throws -> [TestFlowDiagnostic] {
        let application = try coderApplicationWithSafeFileEditingSkill()
        let context = try application.composedContext()

        try Expect.true(
            context.text.contains("Safe file editing"),
            "mode context includes loaded skill name"
        )

        try Expect.true(
            context.text.contains("Read before writing."),
            "mode context includes loaded skill body"
        )

        return [
            .field(
                "mode",
                application.modeID.rawValue
            ),
            .field(
                "contextCharacters",
                String(context.text.count)
            )
        ]
    }

    static func runModeApplicationContextOmitsMissingSkills() async throws -> [TestFlowDiagnostic] {
        let application = try coderApplicationWithSafeFileEditingSkill()
        let context = try application.composedContext()

        try Expect.true(
            application.missingSkillIdentifiers.contains(
                "context-packing"
            ),
            "fixture has missing context-packing skill"
        )

        try Expect.equal(
            context.text.contains("context-packing"),
            false,
            "mode context omits missing skill identifiers from rendered skill body"
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

    static func runModeCoderContextIncludesSafeFileEditingSkill() async throws -> [TestFlowDiagnostic] {
        let application = try coderApplicationWithSafeFileEditingSkill()
        let message = try application.contextMessage()

        guard let message else {
            throw TestFlowAssertionFailure(
                label: "mode coder context includes safe file editing skill",
                message: "Expected mode context message."
            )
        }

        try Expect.equal(
            message.role,
            .system,
            "mode context message role"
        )

        try Expect.true(
            message.content.text.contains("Skill ID: safe-file-editing"),
            "mode context message includes safe-file-editing skill id"
        )

        return [
            .field(
                "role",
                message.role.rawValue
            ),
            .field(
                "textCharacters",
                String(message.content.text.count)
            )
        ]
    }

    static func runModeContextMetadataIncludesModeIDBudgetApproval() async throws -> [TestFlowDiagnostic] {
        let application = try coderApplicationWithSafeFileEditingSkill()
        let context = try application.contextApplication()
        let attributes = context.plan.metadata.attributes

        try Expect.equal(
            attributes["mode_id"],
            "coder",
            "mode context metadata mode id"
        )

        try Expect.equal(
            attributes["mode_budget_posture"],
            "balanced",
            "mode context metadata budget posture"
        )

        try Expect.equal(
            attributes["mode_approval_strictness"],
            "review_bounded_mutation",
            "mode context metadata approval strictness"
        )

        return [
            .field(
                "mode",
                attributes["mode_id"] ?? ""
            ),
            .field(
                "budget",
                attributes["mode_budget_posture"] ?? ""
            ),
            .field(
                "approval",
                attributes["mode_approval_strictness"] ?? ""
            )
        ]
    }

    static func runModeApplicationRequestIncludesModeContextMessage() async throws -> [TestFlowDiagnostic] {
        let application = try coderApplicationWithSafeFileEditingSkill()
        let request = try application.request(
            user: "Patch the formatter."
        )

        try Expect.equal(
            request.tools.map(\.name).sorted(),
            [
                "mutate_files",
                "read_file",
                "scan_paths"
            ],
            "mode request includes filtered mode tools"
        )

        try Expect.true(
            request.messages.contains { message in
                message.role == .system
                    && message.content.text.contains("Skill ID: safe-file-editing")
            },
            "mode request includes mode context message"
        )

        try Expect.equal(
            request.metadata["mode_id"],
            "coder",
            "mode request metadata includes mode id"
        )

        return [
            .field(
                "messages",
                String(request.messages.count)
            ),
            .field(
                "tools",
                request.tools.map(\.name).sorted().joined(separator: ",")
            ),
            .field(
                "mode",
                request.metadata["mode_id"] ?? ""
            )
        ]
    }
}

private extension AgenticFlowTesting {
    static func coderApplicationWithSafeFileEditingSkill() throws -> ModeRuntimeApplication {
        let selection = try ModeCatalog.standard.selection(
            .coder
        )
        let sourceTools = try Agentic.tool.registry(
            toolSets: [
                CoreToolSet()
            ]
        )

        var skills = SkillRegistry()
        try skills.register(
            AgentSkill(
                identifier: "safe-file-editing",
                name: "Safe file editing",
                summary: "Read before writing and prefer targeted edits.",
                body: "Read before writing. Prefer the smallest safe mutation. Report concrete changed paths."
            )
        )

        return try selection.apply(
            tools: sourceTools,
            skills: skills
        )
    }
}
