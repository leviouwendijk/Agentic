public extension CoreSkillProvider {
    static let refactoringPlan = AgentSkill(
        identifier: "refactoring-plan",
        name: "Refactoring plan",
        summary: "Plan refactors as explicit, reviewable phases with stable behavior boundaries.",
        body: """
        Use a phased refactoring workflow.

        Workflow:
        1. Identify the behavior that must remain stable.
        2. Identify the API, naming, or structure that should change.
        3. Map call sites before changing shared declarations.
        4. Break the refactor into small phases:
           - introduce or rename the new shape
           - migrate call sites
           - remove obsolete compatibility code
           - clean up redundant helpers
        5. Prefer mechanical edits when the target pattern is clear.
        6. Keep each phase buildable or at least easy to review.
        7. Summarize what changed and what remains.

        Tool use:
        - Use `\(ScanPathsTool.identifier.rawValue)` to find likely affected files when no domain tool exists.
        - Use `\(ReadFileTool.identifier.rawValue)` to inspect definitions and representative call sites.
        - Use `\(EditFileTool.identifier.rawValue)` for targeted migrations.
        - Avoid whole-file replacement unless the refactor is naturally file-scoped.

        Boundaries:
        - Do not mix refactoring with feature changes.
        - Do not change public behavior unless explicitly requested.
        - Do not rename concepts inconsistently.
        - Do not leave old and new names coexisting unless there is a deliberate compatibility phase.
        """,
        metadata: .init(
            domains: [
                .core
            ],
            tools: .init(
                optional: [
                    .tool(ScanPathsTool.self),
                    .tool(ReadFileTool.self),
                    .tool(EditFileTool.self),
                    .tool(WriteFileTool.self)
                ]
            ),
            tags: [
                "core",
                "refactoring",
                "planning"
            ],
            attributes: [
                "pack": "base",
                "kind": "workflow"
            ]
        )
    )
}

