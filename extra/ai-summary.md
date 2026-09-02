```
[AI-generated summary of the Agentic project]
2026-09-02
```
# Agentic

Agentic is an experimental, provider-neutral agent harness written in Swift.

The project is built around a simple principle:

> Models may reason about and propose actions, but authority and execution remain in deterministic host code.

Agentic is intended for building AI-assisted and agentic workflows that can interact with real software projects and operational systems without giving a model unrestricted ambient access to the machine.

It is developed as part of a wider ecosystem of small Swift libraries. Where possible, Agentic deliberately delegates deterministic mechanics—filesystem scoping, mutation, schemas, process execution, terminal rendering, parsing, and related work—to independently usable libraries rather than reimplementing them inside the harness.

The project is under active development. APIs and package boundaries are still evolving.

## Goals

Agentic is being developed as infrastructure for controlled AI workflows, initially around software engineering and operational automation.

The design emphasizes:

* strongly typed and declarative tool contracts
* explicit distinction between host-only and model-facing capabilities
* deterministic tool invocation
* scoped workspace authority
* inspectable preflight for consequential actions
* risk- and autonomy-aware approval gating
* reusable mutation planning, diffing, and rollback
* durable and inspectable execution state
* provider-independent model integration
* reusable Swift operations instead of shell-output automation
* domain extensions that remain separate from the core harness

The aim is not to make a model itself an execution environment.

Instead, Agentic gives a model a declared set of capabilities. Their schemas, implementation, workspace authority, policy, approval requirements, and actual effects remain controlled by Swift code.

## Safety and execution model

A model response is treated as input to a deterministic execution system, not as authority by itself.

A typical model-facing operation follows a path approximately like:

```text
model response
    ↓
registered typed tool contract
    ↓
schema + typed input validation
    ↓
workspace / capability resolution
    ↓
tool preflight when applicable
    ↓
execution policy
    ├── permitted
    ├── human review required
    └── denied
    ↓
deterministic Swift implementation
    ↓
structured result
```

The implementation is deliberately layered.

### Explicit, declarative tools

Tools are extensible and registered explicitly.

The relevant model/tool execution machinery lives primarily in [AgenticExecution](/leviouwendijk/AgenticExecution). A registered tool has an explicit model-exposure contract: tools can be **model-facing** or remain **host-only**.

This distinction matters. Merely registering an internal capability does not automatically expose it to a language model.

Typed model-facing tools define concrete Swift input types. Their semantic input contracts are built using the separate [Schema](/leviouwendijk/Schema) library, including the `@JSONSchema` macro.

For example, a tool input can remain ordinary Swift:

```swift
@JSONSchema
public struct GitCommitPreparedToolInput:
    Sendable,
    Codable,
    Hashable
{
    /// Commit message for the exact currently staged changes.
    public let message: String
}
```

Documentation comments and schema annotations can therefore remain next to the Swift values they describe instead of being duplicated into hand-authored JSON dictionaries.

Typed tools expose these semantic contracts through the schema layer. When a tool enters the registry, AgenticExecution captures the model-facing schema and typed decoding contract as part of the registered capability.

At transport boundaries, schemas and values lower through [Primitives](/leviouwendijk/Primitives), including its `JSONValue` representation.

Conceptually:

```text
Swift input type
    ↓
@JSONSchema / Schema
    ↓
semantic JSON schema
    ↓
registered tool contract
    ↓
provider / host schema
    ↓
Primitives.JSONValue
    ↓
typed Swift input
```

This keeps the model-facing contract inspectable while retaining normal typed Swift inside the implementation.

### Risk-aware preflight and approval gating

Tool execution is governed by deterministic policy before an operation is allowed to proceed.

The relevant machinery lives primarily in [AgenticExecution](/leviouwendijk/AgenticExecution), including concepts such as:

```text
ActionRisk
ToolPreflight
ToolExecutionPolicy
ExecutionLimits
ToolApprovalHandler
PreparedIntent
```

Each tool declares an inherent risk classification. The runtime evaluates that classification together with the current execution policy, autonomy settings, workspace authority, execution limits, and—where the tool supports it—a deterministic preflight describing the proposed operation.

Conceptually:

```text
typed tool call
    ↓
workspace / capability validation
    ↓
risk classification
    ↓
optional or required preflight
    ↓
execution policy
    ├── permitted
    ├── human review required
    └── denied
```

A preflight can expose concrete information before execution, for example:

```text
affected paths
requested capabilities
estimated writes
estimated byte count
runtime expectations
command or operation details
side effects
diff preview
prepared exact inputs
```

This allows policy and interfaces to evaluate the operation being proposed rather than relying on the model's verbal description of what it intends to do.

Approval requirements are therefore derived from the actual registered capability and execution context.

Observational operations with a sufficiently low risk classification can be permitted by the active execution policy without introducing an artificial review boundary. Mutating or privileged operations can require richer preflight, explicit review, prepared intents, or be denied entirely depending on their declared risk and the authority granted to the run.

The important boundary is that these decisions are made by deterministic host code:

> The model proposes a registered operation. AgenticExecution determines whether that operation is authorized, whether it must first be inspected or approved, and whether it may execute.

A preflight is also useful independently of mandatory approval. A host or user can request inspection of an operation before execution even when the active policy would otherwise permit it.

When human review is required, the runtime suspends at that boundary and exposes the exact pending operation through a `ToolApprovalHandler`. Execution does not continue until the resulting review decision has been resolved.

### Approval presentation is separate from approval policy

The safety decision itself does not live in the UI.

[AgenticInterfaces](/leviouwendijk/AgenticInterfaces) receives review state from the execution layer and is responsible for presenting it to a human and collecting the resulting action.

The current host console is being built using the reusable [Terminal](/leviouwendijk/Terminal) and [ANSI](/leviouwendijk/ANSI) libraries.

The split is intentional:

```text
AgenticExecution
    risk
    preflight
    execution policy
    approval requirement
    prepared intent
    invocation

AgenticInterfaces
    run presentation
    approval presentation
    diff/detail inspection
    interactive run controls

Terminal
    terminal lifecycle
    shell / overlay / focus primitives
    structured terminal presentation
    input and navigation primitives

ANSI
    terminal styling and ANSI representation
```

This means the console does not decide that an operation is safe merely because a particular button or key was pressed. It displays a decision boundary created by the execution layer and returns the user's explicit decision through that boundary.

The same interface model can later support other front ends without moving policy truth into them.

## Scoped workspace authority

Agentic does not treat the process working directory—or the user's home directory—as ambient model authority.

Filesystem semantics are grounded in the separate [Path](/leviouwendijk/Path) library.

`Path` provides the underlying deterministic primitives for path normalization, scoped paths, sandbox containment, access rules, and scanning.

Conceptually, the lower-level path layer answers questions such as:

```text
Is this path actually inside this sandbox?
What is its normalized scoped representation?
Does this path satisfy these deterministic access rules?
```

[AgenticWorkspace](/leviouwendijk/AgenticWorkspace) builds the agent-specific authority model over those primitives.

It adds concepts such as named workspace roots, grants, capabilities, and tool-specific authority.

Conceptually:

```text
Path
    path semantics
    sandbox containment
    scoped resolution
    deterministic access rules
    scanning

AgenticWorkspace
    named roots
    grants
    capabilities
    tool authority
    session-visible workspace access
```

A workspace can therefore expose named roots and capabilities without giving the model arbitrary absolute-path access.

The model deals in explicitly available roots and relative/scoped paths. Expansion to another root is a governed capability change rather than something the model can accomplish merely by emitting another pathname.

This separation is intentional: Agentic does not invent a second path-sandbox implementation. The underlying path and containment mechanics remain in `Path`, while AgenticWorkspace adds agent-specific authority and lifecycle around them.

## File and resource mutation

Agentic does not implement its own ad hoc file-editing engine.

Lower-level filesystem/resource mechanics are shared with the [IO](/leviouwendijk/IO) library, while safe mutation planning and execution are provided by [Writers](/leviouwendijk/Writers).

Writers is responsible for deterministic mutation concepts such as:

```text
create
replace
edit
delete

mutation planning
resource-state validation
edit constraints
diff/change detection
mutation records
rollback planning
rollback application
```

A multi-file mutation can therefore be represented as a coherent typed operation before Agentic adds agent-specific concerns.

Conceptually:

```text
Agentic model-facing mutation request
    ↓
workspace authorization
    ↓
Writers mutation plan
    ↓
diff / changed-resource preview
    ↓
AgenticExecution policy + approval
    ↓
Writers apply
    ↓
mutation records / receipts / artifacts
```

This division is important:

```text
IO / Writers
    know how to perform and describe deterministic filesystem changes

AgenticWorkspace
    knows whether the requested paths are authorized

AgenticExecution
    knows whether the operation may execute now

AgenticInterfaces
    knows how to present a review to the user
```

A model is not entrusted with implementing any of those enforcement layers itself.

The canonical model-facing direction is toward coherent mutation tools backed by the same Writers substrate rather than separate free-form write mechanisms.

## Command and process execution

Agentic does not use a general model-facing:

```text
run_shell(command: String)
```

primitive as its normal command architecture.

Higher-level operations such as Swift builds or Git actions are exposed as typed tools whose implementations call known deterministic libraries or narrowly defined processes.

Examples include operations conceptually like:

```text
swift_build
swift_run_product
git_status
git_diff
git_prepare_commit
git_commit_prepared
git_push
```

Each capability can carry its own schema, risk classification, execution limits, workspace requirements, and preflight behavior rather than reducing execution to an opaque model-generated shell string.

Process execution itself remains a deterministic host capability. Model access is granted to the specific declared operation, not to a generic command interpreter.

Workspace scoping and approval are not substitutes for OS-level sandboxing. Executing genuinely untrusted generated programs requires an additional process/execution sandbox and is treated as a separate security boundary.

## Structured tool plans

Agentic can compose registered capabilities into structured tool plans rather than requiring a model to express an opaque script.

A plan can represent deterministic control structure around known tool calls, including sequencing and scoped execution.

Conceptually:

```text
ToolPlan
    sequence
        ↓
    scoped workspace
        ↓
    registered tool call
        ↓
    result condition
        ├── continue
        ├── skip
        ├── suspend
        └── recover
```

The plan describes orchestration over capabilities that already exist in the registry. It does not gain new authority merely by composing them.

Workspace scope, tool risk, preflight, approval, and execution policy therefore continue to apply at the underlying operation boundary.

This allows more complex workflows to remain inspectable as structured data rather than being lowered into arbitrary generated code.

## Capability inspection

The host can derive a capability manifest from the actual live tool registry.

That manifest can expose information such as:

```text
tool identifier
description
risk
model exposure
workspace targeting support
semantic input schema
```

The model-facing invocation schema is therefore derived from the concrete registered capabilities rather than maintained as a disconnected parallel list.

A host-only tool remains available to trusted runtime code but is omitted from model-facing invocation authority.

This is intended to make the current execution surface auditable.

## Architecture

Agentic is being developed as an ecosystem of Swift packages rather than as one monolithic executable.

### Agentic repositories

| Repository                                            | Responsibility                                                                                                                           |
| ----------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| [Agentic](/leviouwendijk/Agentic)                     | Provider-neutral semantic contracts shared across the harness.                                                                           |
| [AgenticWorkspace](/leviouwendijk/AgenticWorkspace)   | Agent workspace roots, grants, capabilities, and scoped filesystem authority over `Path`.                                                |
| [AgenticExecution](/leviouwendijk/AgenticExecution)   | Tool registration, typed invocation, preflight, execution policy, approval gating, prepared intents, and structured tool-plan execution. |
| [AgenticRuntime](/leviouwendijk/AgenticRuntime)       | Runtime lifecycle, persistent host behavior, coordination, suspension/recovery, and longer-lived execution state.                        |
| [AgenticInterfaces](/leviouwendijk/AgenticInterfaces) | Human-facing run inspection, approval, recovery, and host-console interaction.                                                           |
| [AgenticCLI](/leviouwendijk/AgenticCLI)               | Thin command-line assembly and executable entry point over the reusable packages.                                                        |
| [AgenticAdapters](/leviouwendijk/AgenticAdapters)     | Model-provider adapters, including current Apple Foundation Models and Amazon Bedrock work.                                              |
| [AgenticDomains](/leviouwendijk/AgenticDomains)       | Domain-specific tools such as Swift and Git capabilities without pulling those dependencies into the semantic core.                      |

The boundaries are intended to keep semantic contracts, authority, execution, persistent runtime behavior, provider translation, and human interfaces independently evolvable.

A simplified conceptual view is:

```text
                         AgenticCLI
                             │
                    AgenticInterfaces
                             │
                       AgenticRuntime
                             │
                     AgenticExecution
                        /          \
                 Agentic        AgenticWorkspace
                    ▲
                    │
          ┌─────────┴─────────┐
          │                   │
   AgenticAdapters      AgenticDomains
          │                   │
     model providers     domain libraries
```

This diagram describes responsibilities rather than requiring every SwiftPM dependency to follow the exact same visual hierarchy.

### Important supporting libraries

These are not hidden implementation details. They are part of the architecture.

| Repository                                    | Used for                                                                                       |
| --------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| [Path](/leviouwendijk/Path)                   | Path normalization, scoped paths, sandbox containment, access rules, and scanning.             |
| [IO](/leviouwendijk/IO)                       | General filesystem and resource mechanics.                                                     |
| [Writers](/leviouwendijk/Writers)             | Safe mutation planning, application, diffs, constraints, records, and rollback.                |
| [Schema](/leviouwendijk/Schema)               | Semantic schemas and `@JSONSchema` synthesis for typed tool contracts.                         |
| [Primitives](/leviouwendijk/Primitives)       | Shared value primitives, including `JSONValue`, used at serialization boundaries.              |
| [Terminal](/leviouwendijk/Terminal)           | Reusable terminal interaction, presentation, shell, focus, overlay, and navigation primitives. |
| [ANSI](/leviouwendijk/ANSI)                   | ANSI styling and terminal representation used beneath `Terminal` and command interfaces.       |
| [Difference](/leviouwendijk/Difference)       | Structured difference and diff representation used by mutation and inspection flows.           |
| [Concatenation](/leviouwendijk/Concatenation) | Provenance-aware source composition and retained context materialization.                      |

Other supporting libraries are integrated as their deterministic capabilities become relevant to the harness.

The underlying principle is:

> A useful deterministic primitive should generally remain useful without Agentic.

## Reusable domain operations

A broader architectural rule across the ecosystem is:

> The reusable Swift operation is the product. A CLI and an Agentic tool are sibling interfaces over it.

Where practical, ordinary libraries expose typed operations:

```text
typed input
    ↓
domain operation
    ↓
typed result
```

Those operations can then be consumed independently:

```text
                       domain library
                       /            \
                  CLI                 AgenticDomains
                                           ↓
                                        Agentic
```

Agentic therefore does not need to execute a CLI and scrape its terminal output when a native Swift API already exists.

Serialization into model-facing values happens at the tool boundary, not throughout the underlying library.

This also keeps Agentic-specific concerns out of lower-level libraries.

A domain operation should not need to know about:

```text
language models
tool-call protocols
approval prompts
model adapters
agent transcripts
Agentic JSON envelopes
```

Those concerns belong in the adapter between the deterministic operation and the harness.

## Domain extensions

[AgenticDomains](/leviouwendijk/AgenticDomains) provides the extension boundary for capabilities that are useful to agents but do not belong in the core harness.

Examples include:

```text
AgenticSwift
AgenticGit
AgenticWeb
```

and potentially further domains for media, imagery, accounting, business systems, structural code intelligence, and other specialized workflows.

The intended dependency direction is one-way:

```text
domain library
      ↓
AgenticDomains adapter
      ↓
Agentic

domain library never imports Agentic merely to become tool-capable
```

This lets domain libraries remain ordinary reusable Swift libraries while AgenticDomains supplies model schemas, tool metadata, risk classification, workspace requirements, and governed invocation.

## Model providers

Agentic itself is intended to remain provider-neutral.

Provider-specific translation belongs in [AgenticAdapters](/leviouwendijk/AgenticAdapters).

Current adapter work includes:

* Apple Foundation Models
* Amazon Bedrock

The Bedrock implementation builds on the lightweight [AWSConnector](/leviouwendijk/AWSConnector) Swift library instead of introducing AWS runtime types into the semantic Agentic packages.

The same execution, workspace, approval, transcript, and tool contracts can therefore remain independent of the provider underneath them.

Conceptually:

```text
Agentic runtime
    ↓
provider-neutral AgentRequest
    ↓
AgenticAdapters
    ├── Apple Foundation Models
    └── Amazon Bedrock
    ↓
provider response
    ↓
provider-neutral AgentResponse
```

Provider capabilities such as tool calling, streaming, token accounting, context limits, or modalities can be represented by the adapter without transferring provider-specific execution authority into the rest of the harness.

## Interfaces

The terminal host is only one possible interface over the runtime.

The current stack separates:

```text
ANSI
    terminal representation

Terminal
    reusable terminal mechanics

AgenticInterfaces
    Agentic-specific interaction semantics

AgenticCLI
    executable assembly
```

This is intended to allow future interfaces—such as richer terminal applications, editor integrations, native applications, or remote control surfaces—to interact with the same runtime and approval boundaries rather than each implementing their own version of them.

In particular, a new interface should not need to reimplement:

```text
risk classification
workspace authority
preflight
approval policy
tool execution
prepared intents
```

It should consume those states and present them.

## Current development

Agentic is not yet a finished general-purpose framework.

The current implementation already includes substantial parts of the deterministic harness, while active work continues across areas such as:

* persistent host and console execution
* richer run inspection and recovery controls
* structured tool plans
* approval and prepared-intent workflows
* workspace-scoped multi-repository execution
* safe multi-file mutation
* Git and Swift domain tooling
* provider adapters
* semantic search and targeted context retrieval
* model routing
* durable sessions and transcripts
* resilience and recovery mechanics
* workflow and orchestration primitives

Longer-term work includes:

* richer memory and retrieval
* workflow orchestration
* supervised subagents
* additional interface transports
* multimodal resources
* stronger execution sandboxing for untrusted code
* broader domain and business integrations

The project deliberately prioritizes **bounded, typed, inspectable execution before broader autonomy**.

## Status

Agentic is an active experimental project.

Expect breaking API changes while the architecture settles.

The repositories are public in part so that the implementation, package boundaries, and safety mechanisms can be inspected directly rather than relying only on high-level descriptions.
