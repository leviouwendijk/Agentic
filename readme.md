# Agentic

Provider-agnostic semantic framework for building agent systems in Swift.

`Agentic` defines the shared authoring and semantic vocabulary used across the wider ecosystem: domains, tools, programs, inference, realizations, optimization, recovery, model interaction contracts, and the macros that bind those declarations together.

> Under active development. APIs are intentionally still evolving.

For a broader generated overview, see [AI summary](extra/ai-summary.md).

## This repository

The package currently exposes:

- `Agentic` — generic semantic contracts and authoring primitives.
- `AgenticStandard` — concrete declarations for the built-in `Standard` domain, including standard tools, programs, inferences, and related behavior.
- `t_agentic` — the canonical executable regression suite, backed by the `AgenticTesting` target and the lightweight [`Testing`](https://github.com/leviouwendijk/Testing) library.

The intended architectural split is:

```text
Agentic
    semantic contracts and authoring

AgenticStandard
    built-in concrete Standard-domain declarations

AgenticExecution
    mechanical tool execution, approval, exposure, and execution state

AgenticRuntime
    run orchestration, tool loop, suspension/resume, and program execution

AgenticInterfaces
    interaction and presentation contracts

AgenticHost
    orchestration across Runtime and Interfaces

AgenticCLI
    executable composition
```

`AgenticStandard` intentionally does not depend on `AgenticExecution`.

## Active Agentic ecosystem

- [Agentic](https://github.com/leviouwendijk/Agentic) — Semantic core and built-in `AgenticStandard` declarations.
- [AgenticModels](https://github.com/leviouwendijk/AgenticModels) — Model identity, capabilities, routing vocabulary, and model-facing substrate.
- [AgenticProviders](https://github.com/leviouwendijk/AgenticProviders) — Provider installation and provider/gateway implementations.
- [AgenticSkills](https://github.com/leviouwendijk/AgenticSkills) — Skills, skill metadata, loading, and skill infrastructure.
- [Workspace](https://github.com/leviouwendijk/Workspace) — Scoped workspace roots, authority, grants, and capabilities.
- [AgenticIO](https://github.com/leviouwendijk/AgenticIO) — Agent-facing IO and source/context operations.
- [AgenticExecution](https://github.com/leviouwendijk/AgenticExecution) — Mechanical tool execution, approval, exposure, prepared execution state, and ToolPlan execution.
- [AgenticRuntime](https://github.com/leviouwendijk/AgenticRuntime) — Runtime lifecycle, tool loop, suspension/resume, interaction boundaries, and program execution.
- [AgenticUsage](https://github.com/leviouwendijk/AgenticUsage) — Usage, token, cost, and related accounting infrastructure.
- [AgenticMedia](https://github.com/leviouwendijk/AgenticMedia) — Media and multimodal capabilities.
- [AgenticInterfaces](https://github.com/leviouwendijk/AgenticInterfaces) — Human-facing interaction and presentation contracts.
- [AgenticHost](https://github.com/leviouwendijk/AgenticHost) — Host orchestration across runtime and interfaces.
- [AgenticDomains](https://github.com/leviouwendijk/AgenticDomains) — Domain-specific integrations.
- [AgenticCLI](https://github.com/leviouwendijk/AgenticCLI) — Ready-made command-line composition for the Agentic stack.

## Superseded package boundaries

Several earlier repositories have been folded into simpler ownership boundaries and should no longer be treated as the architectural source of truth:

- `AgenticInference` → inference semantics now live in `Agentic`.
- `AgenticPrograms` → program semantics now live in `Agentic`.
- `AgenticOptimizer` → optimization semantics now live in `Agentic`.
- `AgenticAdapters` → provider-independent inference adapter semantics now live in `Agentic`; provider integrations belong in `AgenticProviders`.
- `AgenticRecovery` → recovery vocabulary and policy semantics now live in `Agentic`.
- `AgenticWorkspace` → replaced by the standalone `Workspace` package.
- `AgenticTools` → generic tool semantics live in `Agentic`; built-in concrete tools live in `AgenticStandard`.
- `AgenticTestFlows` → removed as a separate target; the canonical test target is `AgenticTesting`.

This repository also consumes `Testing` directly. `TestFlows` is no longer part of the Agentic test dependency path.

## Testing

Run the canonical regression suite with:

```zsh
swift run t_agentic
```

`AgenticTesting` contains the shared fixtures and the unified executable suite.

## Significant supporting libraries

- [Primitives](https://github.com/leviouwendijk/Primitives) — Shared low-level values and utilities, including `JSONValue` and JSON coding policy.
- [Schema](https://github.com/leviouwendijk/Schema) — Schema types and `@JSONSchema` synthesis.
- [Macros](https://github.com/leviouwendijk/Macros) — Shared macro infrastructure.
- [Testing](https://github.com/leviouwendijk/Testing) — Lightweight executable testing primitives, diagnostics, suites, and runners.
- [Guidelines](https://github.com/leviouwendijk/Guidelines) — Structured guidelines and rationale metadata.
- [GuidelinesSearch](https://github.com/leviouwendijk/GuidelinesSearch) — Guideline discovery and retrieval.
- [Search](https://github.com/leviouwendijk/Search) — Deterministic source search and ranking.
- [Difference](https://github.com/leviouwendijk/Difference) — Structured differences and diff representation.
- [Errors](https://github.com/leviouwendijk/Errors) — Shared error primitives.
- [IO](https://github.com/leviouwendijk/IO) — Filesystem and resource IO primitives.
- [Terminal](https://github.com/leviouwendijk/Terminal) — Reusable terminal interaction and TUI primitives.

