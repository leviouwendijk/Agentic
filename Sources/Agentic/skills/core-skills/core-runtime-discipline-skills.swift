public extension CoreSkillProvider {
    static let costAwareContexting = AgentSkill(
        identifier: "cost-aware-contexting",
        name: "Cost-aware contexting",
        summary: "Avoid expensive broad context loads by preferring schemas, summaries, indexes, and selected records.",
        body: """
        Keep context small, targeted, and worth its cost.

        Workflow:
        1. Before loading large files, archives, transcripts, logs, ledgers, or multi-year datasets, ask what exact decision the context must support.
        2. Prefer summaries, schemas, indexes, file names, symbol lists, search results, and selected records before raw bulk content.
        3. Use `\(ScanPathsTool.identifier.rawValue)` to discover candidate files before reading broad contents.
        4. Use `\(ReadFileTool.identifier.rawValue)` with the smallest useful range when the relevant file is known.
        5. When domain tools exist, prefer deterministic parse/filter/search/aggregate tools over dumping raw data into the model.
        6. Escalate to broader context only when the narrow context is insufficient, and state why.
        7. Drop stale context when newer tool output supersedes it.

        Cost discipline:
        - Do not load multi-year raw history when a period summary, schema, index, or similar-record lookup would answer the task.
        - Do not read whole files just to discover structure.
        - Do not include repeated content unless the repetition itself matters.
        - Do not preserve irrelevant background merely because it was loaded earlier.

        Output discipline:
        - Name the exact sources you used.
        - Name any important source you deliberately did not load.
        - When context was minimized, explain the selected slice briefly.
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
                "cost",
                "retrieval"
            ],
            attributes: [
                "pack": "base",
                "kind": "workflow",
                "phase": "runtime-discipline"
            ]
        )
    )

    static let toolFirstRetrieval = AgentSkill(
        identifier: "tool-first-retrieval",
        name: "Tool-first retrieval",
        summary: "Use available retrieval and inspection tools before relying on memory, guessing, or broad reads.",
        body: """
        Prefer tool-backed retrieval over guessing.

        Workflow:
        1. Identify whether the answer depends on current files, prior transcript events, project state, tool output, or external/domain data.
        2. Use the narrowest available tool that can retrieve or inspect that source.
        3. Prefer catalog/list/search tools before deep-read tools.
        4. Prefer exact identifiers, paths, symbols, timestamps, and ranges over vague descriptions.
        5. If multiple candidates are plausible, inspect enough metadata to choose deliberately.
        6. After retrieving evidence, answer from the retrieved material rather than from memory.
        7. If no relevant tool exists, state the retrieval gap and proceed with an explicit limitation.

        With current core tools:
        - Use `\(ScanPathsTool.identifier.rawValue)` to discover candidate paths.
        - Use `\(ReadFileTool.identifier.rawValue)` to inspect selected file content.
        - Use loaded skills for workflow guidance instead of embedding every behavior in the prompt.

        Avoid:
        - Guessing file names, APIs, or prior decisions when a tool can check.
        - Loading broad context before cheap discovery.
        - Treating a stale prior result as current after file edits or new tool output.
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
                "retrieval",
                "tools",
                "context"
            ],
            attributes: [
                "pack": "base",
                "kind": "workflow",
                "phase": "runtime-discipline"
            ]
        )
    )

    static let preparedIntentExecution = AgentSkill(
        identifier: "prepared-intent-execution",
        name: "Prepared intent execution",
        summary: "For consequential actions, separate proposal, deterministic preparation, approval, execution, and reconciliation.",
        body: """
        Use prepared intents for consequential actions.

        Core pattern:
        1. Observe state with read-only tools.
        2. Propose the desired outcome in natural language.
        3. Ask deterministic host or domain logic to prepare an exact intent.
        4. Review the prepared intent as structured data.
        5. Execute only the exact prepared intent after approval.
        6. Reconcile the result and log what happened.

        A prepared intent should contain:
        - stable intent identifier
        - action type
        - exact target
        - exact inputs
        - expected side effects
        - policy checks passed
        - creation time
        - expiry time when appropriate
        - idempotency key when retries are possible
        - human-readable summary

        Execution rules:
        - Do not let the model improvise final execution parameters for high-impact actions.
        - Do not execute from vague instructions such as “do the thing we discussed.”
        - Execute by prepared intent identifier, not by re-supplying mutable raw parameters.
        - Re-check policy immediately before execution.
        - Refuse execution if the prepared intent expired, changed, was already used, or no longer passes policy.

        This applies especially to:
        - commits and pushes
        - money movement
        - accounting writes
        - deployments
        - destructive file operations
        - external API actions
        """,
        metadata: .init(
            domains: [
                .core
            ],
            tags: [
                "core",
                "approval",
                "intent",
                "safety"
            ],
            attributes: [
                "pack": "base",
                "kind": "workflow",
                "phase": "runtime-discipline"
            ]
        )
    )

    static let approvalSensitiveActions = AgentSkill(
        identifier: "approval-sensitive-actions",
        name: "Approval-sensitive actions",
        summary: "Treat action risk and session autonomy as separate, and surface review needs before acting.",
        body: """
        Treat approval as a runtime safety boundary, not as conversational politeness.

        Workflow:
        1. Identify whether an action is observation, bounded mutation, privileged action, or forbidden action.
        2. Respect the current autonomy mode.
        3. Use tool preflight summaries when available.
        4. Before a risky action, surface what will change, where, and why.
        5. If human review is required, stop at the review boundary instead of simulating approval.
        6. If an action is denied or forbidden, report the denial as a safety result and suggest a safer alternative when possible.

        Review-sensitive actions include:
        - file mutation
        - command execution
        - git mutation
        - writing artifacts outside the workspace
        - deployment
        - network side effects
        - financial/accounting writes
        - irreversible or hard-to-review operations

        Do not:
        - Hide risky side effects inside a harmless-sounding action.
        - Split a privileged action into smaller steps to bypass review.
        - Treat user intent as approval unless the runtime approval mechanism says it is approved.
        - Execute a forbidden action.

        Good approval summaries include:
        - tool name
        - risk category
        - target paths or external targets
        - command preview or action preview
        - estimated writes or side effects
        - reason for the action
        """,
        metadata: .init(
            domains: [
                .core
            ],
            tags: [
                "core",
                "approval",
                "policy",
                "safety"
            ],
            attributes: [
                "pack": "base",
                "kind": "workflow",
                "phase": "runtime-discipline"
            ]
        )
    )

    static let artifactOutputDiscipline = AgentSkill(
        identifier: "artifact-output-discipline",
        name: "Artifact output discipline",
        summary: "Create durable outputs deliberately, with clear purpose, provenance, and review boundaries.",
        body: """
        Treat artifacts as durable outputs, not incidental text.

        Workflow:
        1. Identify whether the user needs an ephemeral answer or a durable artifact.
        2. Choose the smallest artifact that satisfies the task.
        3. Keep artifact content separate from reasoning chatter.
        4. Include provenance when the artifact depends on sources, files, transcript events, or tool output.
        5. Use stable names and clear titles.
        6. Make generated artifacts reviewable before they are used for external publication or execution.
        7. Summarize what was produced and where it belongs.

        Artifact categories:
        - handoff summaries
        - context packs
        - reports
        - diff summaries
        - generated documents
        - prepared prompts
        - client-facing drafts
        - accounting or operational summaries

        Avoid:
        - Mixing artifact text with conversational commentary.
        - Writing files outside the intended workspace or artifact store.
        - Omitting source provenance for factual or operational artifacts.
        - Pretending a rendered/exported artifact exists unless a tool actually created it.

        When artifact tools do not exist yet:
        - Provide the artifact text directly.
        - Mark it clearly as draft content.
        - Do not claim it was saved.
        """,
        metadata: .init(
            domains: [
                .core
            ],
            tags: [
                "core",
                "artifacts",
                "output",
                "provenance"
            ],
            attributes: [
                "pack": "base",
                "kind": "workflow",
                "phase": "runtime-discipline"
            ]
        )
    )

    static let transcriptSummarization = AgentSkill(
        identifier: "transcript-summarization",
        name: "Transcript summarization",
        summary: "Condense conversation history into decisions, state, evidence, and next actions without preserving noise.",
        body: """
        Summarize transcripts as operational state, not as a chronological diary.

        Include:
        1. Current objective.
        2. Decisions already made.
        3. Constraints and preferences that still apply.
        4. Files, tools, domains, and artifacts involved.
        5. Important evidence and where it came from.
        6. Open questions.
        7. Next concrete step.
        8. Things explicitly ruled out.

        Compress away:
        - repeated deliberation
        - abandoned options
        - stale assumptions
        - low-level tool chatter unless it affects state
        - conversational filler

        Preserve exactly:
        - identifiers
        - paths
        - commands
        - tool names
        - API names
        - error messages when still relevant
        - line ranges or source references when available

        Summarization rules:
        - Distinguish facts from guesses.
        - Mark verification state clearly.
        - Do not invent completion.
        - Do not carry forward superseded plans unless they explain a current constraint.
        - Make the summary directly useful to a fresh agent or resumed session.
        """,
        metadata: .init(
            domains: [
                .core
            ],
            tags: [
                "core",
                "transcript",
                "summary",
                "memory"
            ],
            attributes: [
                "pack": "base",
                "kind": "workflow",
                "phase": "runtime-discipline"
            ]
        )
    )

    static let evidenceCitation = AgentSkill(
        identifier: "evidence-citation",
        name: "Evidence citation",
        summary: "Ground factual, code, and operational claims in concrete sources, paths, line ranges, or tool output.",
        body: """
        Ground claims in evidence.

        Workflow:
        1. Identify claims that depend on files, transcripts, tool output, external sources, or current runtime state.
        2. Retrieve the relevant evidence before making the claim.
        3. Preserve source identifiers such as path, line range, symbol name, transcript event, tool call, or artifact name.
        4. State uncertainty when evidence is partial.
        5. Separate evidence-backed facts from inference.
        6. When sources conflict, say so and prefer newer or more direct evidence.

        For code and files:
        - Cite paths and line ranges when available.
        - Prefer exact snippets over paraphrase for small implementation details.
        - After edits, distinguish pre-edit evidence from post-edit evidence.

        For tool output:
        - Refer to the tool result that supports the claim.
        - Do not claim a build, test, render, deploy, or write succeeded unless the corresponding tool output says so.

        For summaries:
        - Preserve the strongest references.
        - Do not cite broad context when a narrow range supports the claim better.

        Avoid:
        - Making confident claims from memory when a tool can check.
        - Using irrelevant evidence because it was recently loaded.
        - Hiding assumptions inside source-backed language.
        """,
        metadata: .init(
            domains: [
                .core
            ],
            tools: .init(
                optional: [
                    .tool(ReadFileTool.self),
                    .tool(ScanPathsTool.self)
                ]
            ),
            tags: [
                "core",
                "evidence",
                "citations",
                "provenance"
            ],
            attributes: [
                "pack": "base",
                "kind": "workflow",
                "phase": "runtime-discipline"
            ]
        )
    )

    static let failureTriage = AgentSkill(
        identifier: "failure-triage",
        name: "Failure triage",
        summary: "Classify failures, isolate likely causes, and choose the next smallest verification step.",
        body: """
        Triage failures before fixing them.

        Workflow:
        1. Capture the exact failure signal.
        2. Classify the failure:
           - syntax or parse error
           - type/API mismatch
           - missing symbol or dependency
           - failed precondition
           - runtime exception
           - test assertion
           - tool invocation failure
           - permission or sandbox denial
           - policy or approval denial
           - external service failure
        3. Identify the earliest reliable failure point.
        4. Separate root-cause candidates from downstream noise.
        5. Inspect the smallest relevant source or configuration region.
        6. Propose the next smallest verification step.
        7. Only patch after the failure is narrow enough to act on.

        With current core tools:
        - Use `\(ScanPathsTool.identifier.rawValue)` when the failing file or path is unknown.
        - Use `\(ReadFileTool.identifier.rawValue)` to inspect the suspected source range.
        - Use `\(EditFileTool.identifier.rawValue)` only after a concrete patch target is known.

        Reporting:
        - Quote or preserve the exact failing identifier/message when useful.
        - Say what is known, what is suspected, and what remains unverified.
        - Do not claim a fix is verified without actual verification output.
        - If no build/test/process tool exists, name that gap directly.
        """,
        metadata: .init(
            domains: [
                .core
            ],
            tools: .init(
                optional: [
                    .tool(ScanPathsTool.self),
                    .tool(ReadFileTool.self),
                    .tool(EditFileTool.self)
                ]
            ),
            tags: [
                "core",
                "failure",
                "debugging",
                "triage"
            ],
            attributes: [
                "pack": "base",
                "kind": "workflow",
                "phase": "runtime-discipline"
            ]
        )
    )
}
