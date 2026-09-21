import Agentic
import Errors
import Foundation
import TestFlows

private struct RecoveryDiagnosticFixtureError:
    SemanticError
{
    let errorPresentation = ErrorPresentation(
        title: "Provider unavailable",
        message: "The fixture provider became unavailable.",
        reason: "The connection ended before a response was received."
    )

    let errorIdentity = ErrorIdentity(
        namespace: "agentic.recovery.fixture",
        code: "provider_unavailable"
    )

    let errorDiagnosticFields: [ErrorDiagnosticField] = [
        .init(
            key: .endpoint,
            value: "/fixture"
        ),
        .init(
            key: .attempt,
            value: 2
        ),
    ]
}

let recoverySemanticFlows: [TestFlow] = [
    TestFlow(
        "recovery-incident-semantics",
        tags: [
            "agentic-recovery",
            "incident",
            "effects",
            "retry-safety",
        ]
    ) {
        let safe = Recovery.Incident(
            kind: .transport_transient,
            stage: .execution,
            effectState: .not_applied,
            retrySafety: .safe,
            scope: .init(
                kind: .inference,
                identifier: "classify-intent"
            ),
            message: "transport ended before a response was received",
            metadata: [
                "provider": "fixture",
            ]
        )

        let uncertain = Recovery.Incident(
            kind: .transport_transient,
            stage: .execution,
            effectState: .unknown,
            retrySafety: .requires_reconciliation,
            scope: .init(
                kind: .tool,
                identifier: "mutation-call"
            ),
            message: "transport ended after dispatch"
        )

        try Expect.equal(
            safe.effectState,
            .not_applied,
            "definitely unapplied work preserves effect certainty"
        )
        try Expect.equal(
            safe.retrySafety,
            .safe,
            "definitely unapplied work may be marked safe to retry"
        )
        try Expect.equal(
            safe.scope.kind,
            .inference,
            "recovery scopes remain generic but typed"
        )
        try Expect.equal(
            uncertain.effectState,
            .unknown,
            "uncertain mutation effects remain explicit"
        )
        try Expect.equal(
            uncertain.retrySafety,
            .requires_reconciliation,
            "unknown mutation effects can require reconciliation"
        )

        return [
            .field(
                "safe_effect",
                safe.effectState.rawValue
            ),
            .field(
                "uncertain_effect",
                uncertain.effectState.rawValue
            ),
            .field(
                "uncertain_retry",
                uncertain.retrySafety.rawValue
            ),
        ]
    },
    TestFlow(
        "recovery-policy-resolution",
        tags: [
            "agentic-recovery",
            "policy",
            "plan",
            "limits",
        ]
    ) {
        let genericPlan = Recovery.Plan(
            steps: [
                .init(
                    action: .propagate,
                    limit: .once
                ),
            ]
        )
        let decodingPlan = Recovery.Plan(
            steps: [
                .init(
                    action: .repair_output,
                    limit: .init(
                        maximumAttempts: 2
                    )
                ),
                .init(
                    action: .propagate,
                    limit: .once
                ),
            ]
        )
        let policy = Recovery.Policy(
            rules: [
                .init(
                    match: .init(
                        kind: .structured_output_invalid
                    ),
                    plan: genericPlan
                ),
                .init(
                    match: .init(
                        kind: .structured_output_invalid,
                        stage: .decoding
                    ),
                    plan: decodingPlan
                ),
            ]
        )
        let incident = Recovery.Incident(
            kind: .structured_output_invalid,
            stage: .decoding,
            effectState: .none,
            retrySafety: .safe,
            scope: .init(
                kind: .inference,
                identifier: "structured-probe"
            ),
            message: "model output did not decode"
        )

        let selected = try Expect.notNil(
            policy.plan(
                for: incident
            ),
            "stage-specific recovery rule resolves before generic rule"
        )
        let first = try Expect.notNil(
            selected.steps.first,
            "resolved plan retains its first recovery step"
        )

        try Expect.equal(
            first.action,
            .repair_output,
            "decoding failures select output repair"
        )
        try Expect.equal(
            first.limit.maximumAttempts,
            2,
            "recovery attempts remain independently bounded"
        )
        let finalPermit = try Expect.notNil(
            first.limit.nextAttempt(
                after: 1
            ),
            "limit constructs its final permitted recovery attempt"
        )

        try Expect.equal(
            finalPermit.number,
            2,
            "constructed permit carries the final legal attempt number"
        )
        try Expect.equal(
            first.limit.nextAttempt(
                after: 2
            ) == nil,
            true,
            "exhausted limit cannot construct another recovery attempt"
        )

        return [
            .field(
                "action",
                first.action.rawValue
            ),
            .field(
                "maximum_attempts",
                String(first.limit.maximumAttempts)
            ),
        ]
    },
    TestFlow(
        "recovery-structured-error-evidence",
        tags: [
            "agentic-recovery",
            "errors",
            "incident",
            "attempt",
            "report",
        ]
    ) {
        let error = RecoveryDiagnosticFixtureError()
        let incident = Recovery.Incident(
            capturing: error,
            kind: .transport_transient,
            stage: .execution,
            effectState: .none,
            retrySafety: .safe,
            scope: .init(
                kind: .adapter,
                identifier: "fixture-provider"
            ),
            metadata: [
                "provider": "fixture",
            ]
        )
        let attempt = Recovery.Attempt(
            capturing: error,
            number: 1,
            action: .retry_same_operation
        )

        let incidentReport = try Expect.notNil(
            incident.report,
            "capturing incident retains the structured ErrorReport"
        )
        let attemptReport = try Expect.notNil(
            attempt.report,
            "failed recovery attempt retains its structured ErrorReport"
        )

        try Expect.equal(
            incident.message,
            error.errorPresentation.message,
            "incident uses the captured presentation message by default"
        )
        try Expect.equal(
            incidentReport.diagnostic.identity,
            error.errorIdentity,
            "incident preserves semantic error identity"
        )
        try Expect.equal(
            incidentReport.diagnostic.fields,
            error.errorDiagnosticFields,
            "incident preserves structured diagnostic fields"
        )
        try Expect.equal(
            attempt.status,
            .failed,
            "capturing attempt defaults to failed action status"
        )
        try Expect.equal(
            attemptReport,
            incidentReport,
            "incident and attempt independently capture equivalent durable error evidence"
        )

        let record = Recovery.Record(
            incident: incident,
            plan: .init(
                steps: [
                    .init(
                        action: .retry_same_operation,
                        limit: .once
                    ),
                ]
            ),
            attempts: [
                attempt,
            ],
            outcome: .failed
        )
        let persisted = try JSONDecoder().decode(
            Recovery.Record.self,
            from: JSONEncoder().encode(
                record
            )
        )

        try Expect.equal(
            persisted,
            record,
            "recovery records preserve ErrorReport evidence through Codable persistence"
        )
        try Expect.equal(
            persisted.incident.report?.diagnostic.identity,
            error.errorIdentity,
            "persisted incident retains structured diagnostic identity"
        )
        try Expect.equal(
            persisted.attempts.first?.report?.diagnostic.identity,
            error.errorIdentity,
            "persisted recovery attempt retains structured diagnostic identity"
        )

        return [
            .field(
                "incident_identity",
                incidentReport.diagnostic.identity?.code
                    ?? "none"
            ),
            .field(
                "attempt_identity",
                attemptReport.diagnostic.identity?.code
                    ?? "none"
            ),
            .field(
                "persisted",
                String(persisted == record)
            ),
        ]
    },
    TestFlow(
        "recovery-record-codable",
        tags: [
            "agentic-recovery",
            "record",
            "attempt",
            "codable",
        ]
    ) {
        let incident = Recovery.Incident(
            kind: .rate_limited,
            stage: .execution,
            effectState: .none,
            retrySafety: .safe,
            scope: .init(
                kind: .adapter,
                identifier: "fixture-model"
            ),
            message: "provider requested retry"
        )
        let plan = Recovery.Plan(
            steps: [
                .init(
                    action: .wait_then_retry,
                    limit: .init(
                        maximumAttempts: 2
                    )
                ),
            ]
        )
        let record = Recovery.Record(
            incident: incident,
            plan: plan,
            attempts: [
                .init(
                    number: 1,
                    action: .wait_then_retry,
                    status: .failed,
                    message: "provider remained rate limited"
                ),
                .init(
                    number: 2,
                    action: .wait_then_retry,
                    status: .succeeded
                ),
            ],
            outcome: .recovered
        )

        let persisted = try JSONDecoder().decode(
            Recovery.Record.self,
            from: JSONEncoder().encode(
                record
            )
        )

        try Expect.equal(
            persisted,
            record,
            "recovery records round-trip as durable semantic values"
        )
        try Expect.equal(
            persisted.attempts.count,
            2,
            "recovery attempts remain separate from semantic operation attempts"
        )

        return [
            .field(
                "kind",
                persisted.incident.kind.rawValue
            ),
            .field(
                "attempts",
                String(persisted.attempts.count)
            ),
            .field(
                "outcome",
                persisted.outcome.rawValue
            ),
        ]
    },
    TestFlow(
        "recovery-state",
        tags: [
            "agentic-recovery",
            "state",
            "reconciliation",
        ]
    ) {
        let applied = Recovery.State(
            reconciled: .applied
        )
        let notApplied = Recovery.State(
            reconciled: .not_applied
        )
        let unknown = Recovery.State(
            reconciled: .unknown
        )

        try Expect.equal(
            applied.retry,
            .unsafe,
            "applied effects cannot be retried"
        )
        try Expect.equal(
            notApplied.retry,
            .safe,
            "definitely unapplied effects may be retried"
        )
        try Expect.equal(
            unknown.retry,
            .requires_reconciliation,
            "unknown effects remain non-retryable"
        )

        let incident = Recovery.Incident(
            kind: .outcome_unknown,
            stage: .execution,
            effectState: .unknown,
            retrySafety: .requires_reconciliation,
            scope: .init(
                kind: .tool,
                identifier: "fixture-mutation"
            ),
            message: "mutation outcome is unknown"
        )
        let attempt = Recovery.Attempt(
            number: 1,
            action: .reconcile,
            status: .succeeded,
            state: applied
        )
        let record = Recovery.Record(
            incident: incident,
            plan: .init(
                steps: [
                    .init(
                        action: .reconcile,
                        limit: .once
                    ),
                ]
            ),
            attempts: [
                attempt,
            ],
            state: applied,
            outcome: .failed
        )

        try Expect.equal(
            attempt.status,
            .succeeded,
            "reconciliation action may succeed independently of the whole recovery"
        )
        try Expect.equal(
            attempt.state,
            applied,
            "attempt records the state it established"
        )
        try Expect.equal(
            record.state,
            applied,
            "record exposes the authoritative final state"
        )
        try Expect.equal(
            record.outcome,
            .failed,
            "recovery may fail even after proving the mutation applied"
        )

        let persisted = try JSONDecoder().decode(
            Recovery.Record.self,
            from: JSONEncoder().encode(
                record
            )
        )

        try Expect.equal(
            persisted,
            record,
            "recovery state survives Codable persistence"
        )

        return [
            .field(
                "status",
                attempt.status.rawValue
            ),
            .field(
                "effect",
                record.state.effect.rawValue
            ),
            .field(
                "retry",
                record.state.retry.rawValue
            ),
            .field(
                "outcome",
                record.outcome.rawValue
            ),
        ]
    },
]
