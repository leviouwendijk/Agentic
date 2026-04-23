public extension CoreSkillProvider {
    static let contextPacking = AgentSkill(
        identifier: "context-packing",
        name: "Context packing",
        summary: "Collect only the context needed for the current task, with clear provenance.",
        body: """
        Build context deliberately instead of loading broad file blobs.

        Workflow:
        1. Start from the user request and identify the smallest facts needed to answer or act.
        2. Prefer known paths and targeted reads over workspace-wide scans.
        3. Use `\(ScanPathsTool.identifier.rawValue)` when you need to discover candidate files.
        4. Use `\(ReadFileTool.identifier.rawValue)` with line windows when only part of a file is relevant.
        5. Keep source boundaries visible: path, line range, and why that source matters.
        6. Separate durable task facts from incidental surrounding text.
        7. When context is incomplete, name the missing fact and the next smallest read that would resolve it.

        Packing priorities:
        - User’s current objective.
        - Relevant current files or snippets.
        - Prior decisions that constrain the change.
        - Existing conventions in nearby code or documents.
        - Tool results that affect correctness.

        Avoid:
        - Loading whole files because a narrow range would do.
        - Keeping stale context after newer tool output contradicts it.
        - Mixing unrelated project background into the active task context.
        """,
        metadata: .init(
            domains: [
                .core
            ],
            tools: .init(
                optional: [
                    .tool(ScanPathsTool.self),
                    .tool(ReadFileTool.self)
                ]
            ),
            tags: [
                "core",
                "context",
                "retrieval"
            ],
            attributes: [
                "pack": "base",
                "kind": "workflow"
            ]
        )
    )
}
