# Agentic

Agentic harness for LLMs in Swift. Provider-agnostic, and extensible ecosystem. Opt-ins to a ready-made CLI, tools, and skills. Or build your own.

> Note: under development, unstable APIs

For a summary overview, see [AI summary](extra/ai-summary.md).

# Index

## Agentic ecosystem

- [Agentic](https://github.com/leviouwendijk/Agentic) — Core provider-agnostic Agentic contracts.
- [AgenticModels](https://github.com/leviouwendijk/AgenticModels) — Model, routing, request/response, and model-facing abstractions.
- [AgenticTools](https://github.com/leviouwendijk/AgenticTools) — Tool definitions, discovery, exposure, and core tool infrastructure.
- [AgenticSkills](https://github.com/leviouwendijk/AgenticSkills) — Skills, skill metadata, loading, and skill infrastructure.
- [AgenticWorkspace](https://github.com/leviouwendijk/AgenticWorkspace) — Scoped workspace authority, roots, grants, and capabilities.
- [AgenticIO](https://github.com/leviouwendijk/AgenticIO) — Agent-facing IO and source/context operations.
- [AgenticExecution](https://github.com/leviouwendijk/AgenticExecution) — Execution policy, preflight, approvals, prepared intents, and tool-plan execution.
- [AgenticRuntime](https://github.com/leviouwendijk/AgenticRuntime) — Runtime lifecycle, sessions, coordination, suspension, recovery, and persistent execution.
- [AgenticUsage](https://github.com/leviouwendijk/AgenticUsage) — Usage, token, cost, and related accounting infrastructure.
- [AgenticMedia](https://github.com/leviouwendijk/AgenticMedia) — Media and multimodal Agentic capabilities.
- [AgenticInterfaces](https://github.com/leviouwendijk/AgenticInterfaces) — Human-facing interaction, host-console UI, approvals, inspection, and run control.
- [AgenticAdapters](https://github.com/leviouwendijk/AgenticAdapters) — Model-provider adapters.
- [AgenticDomains](https://github.com/leviouwendijk/AgenticDomains) — Domain-specific Agentic integrations and tool sets.
- [AgenticCLI](https://github.com/leviouwendijk/AgenticCLI) — Ready-made command-line host for Agentic.

## Significant supporting libraries

* [Path](https://github.com/leviouwendijk/Path) — Paths, scoped paths, sandboxing, access rules, and scanning.
* [IO](https://github.com/leviouwendijk/IO) — Filesystem and resource IO primitives.
* [Writers](https://github.com/leviouwendijk/Writers) — Safe mutation planning, application, diffs, constraints, records, and rollback.
* [Search](https://github.com/leviouwendijk/Search) — Deterministic source search, ranking, retrieval frontiers, and structural verification.
* [Selection](https://github.com/leviouwendijk/Selection) — Source selections and ranges shared between search, reading, and context materialization.
* [Concatenation](https://github.com/leviouwendijk/Concatenation) — Source composition, selection, provenance, caching, and context materialization.
* [Primitives](https://github.com/leviouwendijk/Primitives) — Shared primitives including `JSONValue`.
* [Schema](https://github.com/leviouwendijk/Schema) — Schema types and `@JSONSchema` synthesis.
* [Difference](https://github.com/leviouwendijk/Difference) — Structured differences and diff representation.
* [Terminal](https://github.com/leviouwendijk/Terminal) — Reusable terminal interaction and TUI primitives.
* [ANSI](https://github.com/leviouwendijk/ANSI) — ANSI styling and terminal representation.
* [AWSConnector](https://github.com/leviouwendijk/AWSConnector) — Lightweight Swift AWS connectivity used by the Bedrock adapter.
