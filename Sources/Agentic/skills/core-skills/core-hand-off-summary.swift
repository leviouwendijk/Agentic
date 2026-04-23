public extension CoreSkillProvider {
    static let handoffSummary = AgentSkill(
        identifier: "handoff-summary",
        name: "Handoff summary",
        summary: "Prepare a directly reusable continuation summary with decisions, state, and next steps.",
        body: """
        Produce handoffs that let a fresh agent continue without hidden context.

        Include:
        1. Current goal.
        2. Relevant architectural decisions.
        3. Files changed or intended to change.
        4. Important names, APIs, conventions, and constraints.
        5. Current build or verification state, if known.
        6. Open problems and next concrete step.
        7. Anything explicitly ruled out.

        Format:
        - Write the handoff as direct context for the next agent.
        - Do not include surrounding commentary.
        - Do not tell the next agent to create another handoff.
        - Prefer concise sections over a chronological transcript.
        - Preserve exact identifiers, paths, and commands when they matter.

        Avoid:
        - Private reasoning.
        - Speculation presented as fact.
        - Stale plans that were superseded.
        - Broad background that does not affect the next step.
        """,
        metadata: .init(
            domains: [
                .core
            ],
            tags: [
                "core",
                "handoff",
                "context"
            ],
            attributes: [
                "pack": "base",
                "kind": "workflow"
            ]
        )
    )
}
