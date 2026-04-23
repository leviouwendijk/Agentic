public extension CoreSkillProvider {
    static let safeFileEditing = AgentSkill(
        identifier: "safe-file-editing",
        name: "Safe file editing",
        summary: "Read before writing, edit the smallest safe range, and report concrete file changes.",
        body: """
        Use a conservative file-editing workflow.

        Workflow:
        1. Inspect the target path before mutating it.
        2. Use `\(ReadFileTool.identifier.rawValue)` for the smallest useful line range when the file is already known.
        3. Use `\(ScanPathsTool.identifier.rawValue)` only when the relevant path is unknown or must be discovered.
        4. Prefer `\(EditFileTool.identifier.rawValue)` for targeted line operations.
        5. Use `\(WriteFileTool.identifier.rawValue)` only when replacing an entire file is clearer and safer than line edits.
        6. Keep edits contiguous and reviewable.
        7. Preserve existing style, naming, imports, formatting, comments, and public API shape unless the task explicitly requires changing them.
        8. After mutation, summarize touched paths, edit type, and changed line ranges or diff summary when available.

        Safety rules:
        - Never mutate a file you have not inspected unless the user explicitly asked for a blind write.
        - Never combine unrelated changes in the same edit.
        - Never widen a requested change into cleanup unless the cleanup is required for correctness.
        - Prefer additions or replacements with clear boundaries over broad rewrites.
        - Stop and explain if the available tools cannot make the change safely.
        """,
        metadata: .init(
            domains: [
                .core
            ],
            tools: .init(
                required: [
                    .tool(ReadFileTool.self),
                    .tool(EditFileTool.self)
                ],
                optional: [
                    .tool(ScanPathsTool.self),
                    .tool(WriteFileTool.self)
                ]
            ),
            tags: [
                "core",
                "files",
                "editing",
                "safety"
            ],
            attributes: [
                "pack": "base",
                "kind": "workflow"
            ]
        )
    )
}
