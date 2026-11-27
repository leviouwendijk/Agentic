import Agentic
import Errors
import Foundation
import Primitives
import Schema
import Testing

/// Tool errors as the model reads them: structured payloads, the session's
/// guard over error results, and recovery by code and disposition.
extension ExecutionTesting {
    static func runToolErrorPayloadSemantics() async throws -> [TestDiagnostic] {
        let semantic = try await errorPayload(
            scenario: .semantic,
            risk: .observe
        )
        let structured = try Expect.notNil(
            semantic.error,
            "a semantic error carries its structure"
        )

        try Expect.equal(
            semantic.kind,
            "tool_error",
            "the payload kind is unchanged"
        )
        try Expect.equal(
            semantic.phase,
            "call",
            "the payload names the failing phase"
        )
        try Expect.equal(
            structured.code?.raw,
            "fixture.mail.move_failed",
            "the model gets the tool's own error code, not the execution wrapper's"
        )
        try Expect.equal(
            semantic.message,
            "UID MOVE to Review/noor@example.com failed.",
            "the message is the tool error's own message"
        )
        try Expect.equal(
            structured.suggestion,
            "Write the path with /.",
            "the suggestion reaches the model"
        )
        try Expect.equal(
            structured.disposition,
            .invalid_input,
            "the disposition reaches the model"
        )
        try Expect.isNil(
            structured.fields["password"],
            "secret fields never reach the model"
        )
        try Expect.equal(
            structured.fields["uid_count"],
            .integer(12),
            "ordinary fields reach the model"
        )

        let plain = try await errorPayload(
            scenario: .plain,
            risk: .observe
        )

        try Expect.isNil(
            plain.error,
            "a plain error keeps today's single message"
        )
        try Expect.equal(
            plain.message,
            "plainFailure",
            "a plain Swift error is described by its case"
        )

        let guarded = try await errorPayload(
            scenario: .semantic,
            risk: .observe,
            guard: AddressHandleGuard()
        )

        try Expect.equal(
            guarded.message,
            "UID MOVE to Review/⟦contact:1⟧ failed.",
            "error results pass through the session's payload guard"
        )
        try Expect.false(
            String(describing: guarded).contains("noor@example.com"),
            "no part of a guarded error result keeps the address"
        )

        return [
            .field("code", structured.code?.raw ?? "missing"),
            .field("guarded", guarded.message),
        ]
    }

    static func runToolRecoveryByDisposition() async throws -> [TestDiagnostic] {
        let byDisposition = Recovery.Policy(
            rules: [
                .init(
                    match: .init(
                        scope: .tool,
                        disposition: .transient
                    ),
                    plan: .init(
                        steps: [
                            .init(
                                action: .retry_same_operation,
                                limit: .once
                            ),
                        ]
                    )
                ),
            ]
        )

        let observed = try await semanticExecution(
            scenario: .transient_once,
            risk: .observe,
            recovery: byDisposition
        )

        try Expect.false(
            observed.result.isError,
            "a transient failure of a read-only call is retried without a tool classifier"
        )
        try Expect.equal(
            observed.recovery?.outcome,
            .recovered,
            "the retry is recorded as recovered"
        )
        try Expect.equal(
            observed.recovery?.incident.report?.effectiveDisposition,
            .transient,
            "the synthesized incident keeps the error's evidence"
        )

        let mutating = try await semanticExecution(
            scenario: .transient_once,
            risk: .boundedmutate,
            recovery: byDisposition
        )

        try Expect.true(
            mutating.result.isError,
            "a transient failure of a mutating call is never retried blindly"
        )
        try Expect.isNil(
            mutating.recovery,
            "no incident is invented for a mutating call"
        )

        let byCode = Recovery.Policy(
            rules: [
                .init(
                    match: .init(
                        code: "fixture.mail"
                    ),
                    plan: .init(
                        steps: [
                            .init(
                                action: .retry_same_operation,
                                limit: .once
                            ),
                        ]
                    )
                ),
            ]
        )
        let incident = Recovery.Incident(
            capturing: SemanticFixtureMailError.moveFailed,
            kind: .transport_transient,
            stage: .execution,
            effectState: .none,
            retrySafety: .safe,
            scope: .init(kind: .tool)
        )

        try Expect.notNil(
            byCode.plan(for: incident),
            "a rule matches a namespace anywhere in the incident's report"
        )
        try Expect.isNil(
            Recovery.Policy(
                rules: [
                    .init(
                        match: .init(code: "fixture.smtp"),
                        plan: .init(steps: [])
                    ),
                ]
            ).plan(for: incident),
            "a rule for another namespace does not match"
        )
        try Expect.equal(
            incident.report?.diagnostic[field: "password"]?.value,
            .redacted,
            "a stored incident never keeps secrets"
        )

        return [
            .field("observed", observed.recovery?.outcome.rawValue ?? "missing"),
            .field("mutating", String(mutating.result.isError)),
        ]
    }
}

private extension ExecutionTesting {
    static func errorPayload(
        scenario: SemanticFailureScenario,
        risk: ActionRisk,
        guard shield: (any ToolPayloadGuard)? = nil
    ) async throws -> ToolErrorPayload {
        let execution = try await semanticExecution(
            scenario: scenario,
            risk: risk,
            recovery: nil,
            guard: shield
        )

        try Expect.true(
            execution.result.isError,
            "the failing call answers with an error result"
        )

        return try execution.result.output.decode(
            ToolErrorPayload.self
        )
    }

    static func semanticExecution(
        scenario: SemanticFailureScenario,
        risk: ActionRisk,
        recovery: Recovery.Policy?,
        guard shield: (any ToolPayloadGuard)? = nil
    ) async throws -> ToolExecution.Result {
        let tool = SemanticFailureTool(
            probe: SemanticFailureProbe()
        )
        let invoker = ToolExecutor(
            registry: try ToolRegistry {
                tool
            },
            policy: ToolExecutionPolicy(
                autonomyMode: .auto_observe
            ),
            recovery: recovery
        )
        let services =
            try shield.map {
                try CapabilityServices().inserting(
                    ToolPayloadGuarding($0)
                )
            }
            ?? CapabilityServices()

        let invocation = try await invoker.invoke(
            ToolInvocation(
                id: "semantic-\(scenario.rawValue)-\(risk.rawValue)",
                tool: SemanticFailureTool.definition.identifier,
                arguments: try JSONValue.encoding(
                    SemanticFailureInput(
                        scenario: scenario.rawValue,
                        risk: risk.rawValue
                    )
                )
            ),
            context: CapabilityContext(
                services: services
            ),
            approvalHandler: SemanticFailureApprovalHandler()
        )

        return try Expect.notNil(
            invocation.execution,
            "the call executes through the governed ToolExecutor path"
        )
    }
}

private enum SemanticFailureScenario: String, Sendable {
    case semantic
    case plain
    case transient_once
}

private enum SemanticFixtureMailError:
    SemanticError,
    ErrorNamespaced,
    ErrorDispositionProviding
{
    case moveFailed

    static let errorNamespace = "fixture.mail"

    var errorCode: String {
        "move_failed"
    }

    var errorDisposition: ErrorDisposition? {
        .invalid_input
    }

    var errorPresentation: ErrorPresentation {
        .init(
            message: "UID MOVE to Review/noor@example.com failed.",
            reason: "NO [NONEXISTENT] Mailbox does not exist.",
            recoverySuggestion: "Write the path with /.",
            reasonOrigin: .remote
        )
    }

    var errorDiagnosticFields: [ErrorDiagnosticField] {
        [
            .init(
                key: "uid_count",
                value: 12
            ),
            .init(
                key: "password",
                value: "hunter2",
                sensitivity: .secret
            ),
        ]
    }
}

private enum SemanticFailurePlainError: Error {
    case plainFailure
}

private struct SemanticFailureInput:
    Sendable,
    Codable,
    JSONSchemaProviding
{
    let scenario: String
    let risk: String

    static var jsonschema: JSONSchema {
        .any
    }
}

private struct SemanticFailureOutput:
    Sendable,
    Codable,
    JSONSchemaProviding
{
    let value: String

    static var jsonschema: JSONSchema {
        .any
    }
}

private actor SemanticFailureProbe {
    private var calls = 0

    func next() -> Int {
        calls += 1
        return calls
    }
}

private struct SemanticFailureTool: Tool {
    typealias Input = SemanticFailureInput
    typealias Output = SemanticFailureOutput

    static let definition = ToolDefinition(
        identifier: "semantic_failure_fixture",
        purpose: "Fails with structured, plain and transient errors.",
        risk: .boundedmutate
    )

    let probe: SemanticFailureProbe

    func preflight(
        _ input: Input,
        in _: CapabilityContext
    ) async throws -> ToolPreflight {
        let risk = ActionRisk(rawValue: input.risk) ?? .observe

        return ToolPreflight(
            tool: Self.definition.identifier,
            risk: risk,
            summary: "semantic failure fixture",
            sideEffects: risk.defaultSideEffects
        )
    }

    func call(
        _ input: Input,
        in _: CapabilityContext
    ) async throws -> Output {
        switch SemanticFailureScenario(rawValue: input.scenario) {
        case .semantic:
            throw SemanticFixtureMailError.moveFailed

        case .plain:
            throw SemanticFailurePlainError.plainFailure

        case .transient_once:
            guard await probe.next() > 1 else {
                throw URLError(.timedOut)
            }
            return .init(value: "retried")

        case nil:
            throw SemanticFailurePlainError.plainFailure
        }
    }
}

private struct SemanticFailureApprovalHandler:
    ToolApprovalHandler
{
    func decide(
        on review: ToolInvocation.Review
    ) async throws -> ApprovalDecision {
        _ = review
        return .approved
    }
}

/// Stands in for the Sensitivity shield: one known address becomes a
/// handle in every string that leaves a tool.
private struct AddressHandleGuard: ToolPayloadGuard {
    func resolving(
        _ arguments: JSONValue,
        for _: ToolIdentifier
    ) async throws -> JSONValue {
        arguments
    }

    func protecting(
        _ value: JSONValue,
        from tool: ToolIdentifier
    ) async -> JSONValue {
        switch value {
        case .string(let text):
            return .string(await protecting(text, from: tool))

        case .array(let values):
            var protected: [JSONValue] = []
            for value in values {
                protected.append(await protecting(value, from: tool))
            }
            return .array(protected)

        case .object(let values):
            var protected: [String: JSONValue] = [:]
            for (key, value) in values {
                protected[key] = await protecting(value, from: tool)
            }
            return .object(protected)

        default:
            return value
        }
    }

    func protecting(
        _ text: String,
        from _: ToolIdentifier
    ) async -> String {
        text.replacingOccurrences(
            of: "noor@example.com",
            with: "⟦contact:1⟧"
        )
    }
}
