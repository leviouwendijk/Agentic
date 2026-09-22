import Agentic
import Testing

let recoveryTighteningFlows: [TestFlow] = [
    TestFlow(
        "recovery-policy-specificity",
        tags: [
            "agentic-recovery",
            "policy",
            "match",
            "specificity",
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
        let executionPlan = Recovery.Plan(
            steps: [
                .init(
                    action: .wait_then_retry,
                    limit: .once
                ),
            ]
        )
        let safeInferencePlan = Recovery.Plan(
            steps: [
                .init(
                    action: .retry_same_operation,
                    limit: .init(
                        maximumAttempts: 2
                    )
                ),
            ]
        )
        let uncertainToolPlan = Recovery.Plan(
            steps: [
                .init(
                    action: .reconcile,
                    limit: .once
                ),
            ]
        )

        let policy = Recovery.Policy(
            rules: [
                .init(
                    match: .init(
                        kind: .transport_transient
                    ),
                    plan: genericPlan
                ),
                .init(
                    match: .init(
                        kind: .transport_transient,
                        stage: .execution
                    ),
                    plan: executionPlan
                ),
                .init(
                    match: .init(
                        kind: .transport_transient,
                        stage: .execution,
                        scope: .inference,
                        effectState: Recovery.EffectState.none,
                        retrySafety: .safe
                    ),
                    plan: safeInferencePlan
                ),
                .init(
                    match: .init(
                        kind: .transport_transient,
                        stage: .execution,
                        scope: .tool,
                        effectState: .unknown,
                        retrySafety: .requires_reconciliation
                    ),
                    plan: uncertainToolPlan
                ),
            ]
        )

        let safeInference = Recovery.Incident(
            kind: .transport_transient,
            stage: .execution,
            effectState: Recovery.EffectState.none,
            retrySafety: .safe,
            scope: .init(
                kind: .inference,
                identifier: "classify"
            ),
            message: "provider connection ended before output"
        )
        let uncertainTool = Recovery.Incident(
            kind: .transport_transient,
            stage: .execution,
            effectState: .unknown,
            retrySafety: .requires_reconciliation,
            scope: .init(
                kind: .tool,
                identifier: "write-state"
            ),
            message: "connection ended after dispatch"
        )

        let inferencePlan = try Expect.notNil(
            policy.plan(
                for: safeInference
            ),
            "safe inference incident resolves a recovery plan"
        )
        let inferenceStep = try Expect.notNil(
            inferencePlan.steps.first,
            "safe inference plan has a first step"
        )
        let toolPlan = try Expect.notNil(
            policy.plan(
                for: uncertainTool
            ),
            "uncertain tool incident resolves a recovery plan"
        )
        let toolStep = try Expect.notNil(
            toolPlan.steps.first,
            "uncertain tool plan has a first step"
        )

        try Expect.equal(
            inferenceStep.action,
            .retry_same_operation,
            "most-specific safe inference rule wins over broader transport rules"
        )
        try Expect.equal(
            toolStep.action,
            .reconcile,
            "unknown tool effects select reconciliation rather than blind retry"
        )

        return [
            .field(
                "inference_action",
                inferenceStep.action.rawValue
            ),
            .field(
                "tool_action",
                toolStep.action.rawValue
            ),
        ]
    },
    TestFlow(
        "recovery-decision",
        tags: [
            "agentic-recovery",
            "decision",
            "plan",
        ]
    ) {
        let step = Recovery.Plan.Step(
            action: .wait_then_retry,
            limit: .init(
                maximumAttempts: 3
            )
        )
        let decision = Recovery.Decision(
            step: step
        )

        try Expect.equal(
            decision.action,
            .wait_then_retry,
            "decision preserves the selected recovery action"
        )
        try Expect.equal(
            decision.limit.maximumAttempts,
            3,
            "decision preserves the selected step limit"
        )

        return [
            .field(
                "action",
                decision.action.rawValue
            ),
            .field(
                "maximum_attempts",
                String(decision.limit.maximumAttempts)
            ),
        ]
    },
    TestFlow(
        "recovery-budget",
        tags: [
            "agentic-recovery",
            "budget",
            "limits",
            "loop-safety",
        ]
    ) {
        let budget = Recovery.Budget(
            perIncident: 2,
            perScope: 4,
            total: 6
        )

        let permit = try Expect.notNil(
            budget.nextAttempt(
                after: .init(
                    incidentAttempts: 1,
                    scopeAttempts: 3,
                    totalAttempts: 5
                )
            ),
            "budget constructs a permit while every bound has capacity"
        )

        try Expect.equal(
            permit.usage.incidentAttempts,
            2,
            "permit carries post-consumption incident usage"
        )
        try Expect.equal(
            permit.usage.scopeAttempts,
            4,
            "permit carries post-consumption scope usage"
        )
        try Expect.equal(
            permit.usage.totalAttempts,
            6,
            "permit carries post-consumption total usage"
        )
        try Expect.equal(
            budget.nextAttempt(
                after: .init(
                    incidentAttempts: 2,
                    scopeAttempts: 3,
                    totalAttempts: 5
                )
            ) == nil,
            true,
            "per-incident exhaustion prevents permit construction"
        )
        try Expect.equal(
            budget.nextAttempt(
                after: .init(
                    incidentAttempts: 1,
                    scopeAttempts: 4,
                    totalAttempts: 5
                )
            ) == nil,
            true,
            "per-scope exhaustion prevents permit construction"
        )
        try Expect.equal(
            budget.nextAttempt(
                after: .init(
                    incidentAttempts: 1,
                    scopeAttempts: 3,
                    totalAttempts: 6
                )
            ) == nil,
            true,
            "total exhaustion prevents permit construction"
        )
        try Expect.equal(
            Recovery.Budget.unlimited.nextAttempt(
                after: .init(
                    incidentAttempts: 100,
                    scopeAttempts: 100,
                    totalAttempts: 100
                )
            ) != nil,
            true,
            "unlimited budget can always construct another permit"
        )
        try Expect.equal(
            Recovery.Outcome.suspended.rawValue,
            "suspended",
            "suspension has an explicit recoverable outcome state"
        )

        return [
            .field(
                "per_incident",
                String(budget.perIncident ?? 0)
            ),
            .field(
                "per_scope",
                String(budget.perScope ?? 0)
            ),
            .field(
                "total",
                String(budget.total ?? 0)
            ),
        ]
    },
]
