import Testing

enum ExecutionTestSuite {
    static let testSuite = TestSuite(
        "execution",
        title: "Agentic execution tests"
    ) {
        diagnosticTest("tool-execution-observations", tags: ["execution", "observations"]) {
            try await ExecutionTesting.runExecutionObservations()
        }

        diagnosticTest(
            "prepared-intent-operation-authority",
            tags: [
                "agentic-execution",
                "prepared-intent",
                "prepared-operation",
                "persistence",
                "lifecycle",
                "version",
            ]
        ) {
            try await ExecutionTesting
                .runPreparedIntentOperationAuthority()
        }

        diagnosticTest(
            "prepared-operation-registry",
            tags: [
                "agentic-execution",
                "prepared-operation",
                "registry",
                "persistence",
                "typing",
                "version",
            ]
        ) {
            try await ExecutionTesting
                .runPreparedOperationRegistry()
        }

        diagnosticTest(
            "prepared-operation-envelope",
            tags: [
                "agentic-execution",
                "prepared-operation",
                "persistence",
                "schema",
                "typing",
                "version",
            ]
        ) {
            try await ExecutionTesting
                .runPreparedOperationEnvelope()
        }

        diagnosticTest(
            "find-capabilities",
            tags: [
                "agentic-execution",
                "capabilities",
                "discovery",
                "visibility",
            ]
        ) {
            try await ExecutionTesting
                .runFindCapabilities()
        }

        diagnosticTest(
            "tool-inventory",
            tags: [
                "agentic-execution",
                "tools",
                "inventory",
                "installation",
            ]
        ) {
            try await ExecutionTesting
                .runToolInventory()
        }

        diagnosticTest(
            "tool-plan-run-retry-resume",
            tags: [
                "agentic-execution",
                "tool-plan",
                "run",
                "interruption",
                "retry",
                "resume",
            ]
        ) {
            try await ExecutionTesting
                .runToolPlanRetryAndResume()
        }

        diagnosticTest(
            "tool-plan-run-failure-evidence",
            tags: [
                "agentic-execution",
                "tool-plan",
                "run",
                "failure",
                "evidence",
                "recovery",
                "interruption",
            ]
        ) {
            try await ExecutionTesting
                .runToolPlanFailureEvidence()
        }

        diagnosticTest(
            "tool-plan-run-retry-safety",
            tags: [
                "agentic-execution",
                "tool-plan",
                "run",
                "recovery",
                "retry",
                "retry-safety",
                "interruption",
            ]
        ) {
            try await ExecutionTesting
                .runToolPlanRetrySafety()
        }

        diagnosticTest(
            "tool-plan-failure-branch-retry-resume",
            tags: [
                "agentic-execution",
                "tool-plan",
                "on-failure",
                "path",
                "resolution",
                "retry",
                "resume",
            ]
        ) {
            try await ExecutionTesting
                .runToolPlanFailureBranchRetryResume()
        }

        diagnosticTest(
            "tool-plan-run-skip-resume",
            tags: [
                "agentic-execution",
                "tool-plan",
                "run",
                "interruption",
                "skip",
                "resume",
            ]
        ) {
            try await ExecutionTesting
                .runToolPlanSkipAndResume()
        }

        diagnosticTest(
            "tool-plan-execution-policy-model",
            tags: [
                "agentic-execution",
                "tool-plan",
                "execution-policy",
                "interruption",
            ]
        ) {
            try ExecutionTesting
                .runToolPlanExecutionPolicyModel()
        }

        diagnosticTest(
            "tool-plan-single-step-start",
            tags: [
                "agentic-execution",
                "tool-plan",
                "execution-policy",
                "single-step",
                "interruption",
            ]
        ) {
            try await ExecutionTesting
                .runToolPlanSingleStepStart()
        }

        diagnosticTest(
            "tool-plan-single-step-resume",
            tags: [
                "agentic-execution",
                "tool-plan",
                "execution-policy",
                "single-step",
                "resume",
                "continuous",
                "interruption",
            ]
        ) {
            try await ExecutionTesting
                .runToolPlanSingleStepResume()
        }

        diagnosticTest(
            "tool-plan-approval-skip-continues",
            tags: [
                "agentic-execution",
                "tool-plan",
                "approval",
                "skip",
                "continuation",
            ]
        ) {
            try await ExecutionTesting
                .runToolPlanApprovalSkip()
        }

        diagnosticTest(
            "tool-execution-targeting",
            tags: [
                "agentic-execution",
                "tools",
                "targeting",
                "execution",
                "model-facing",
            ]
        ) {
            try await ExecutionTesting
                .runToolExecutionTargeting()
        }

        diagnosticTest(
            "tool-call-resolver",
            tags: [
                "agentic-execution",
                "tools",
                "resolver",
                "visibility",
                "approval",
            ]
        ) {
            try await ExecutionTesting
                .runToolCallResolver()
        }

        diagnosticTest(
            "tool-call-resolver-observer",
            tags: [
                "agentic-execution",
                "tools",
                "resolver",
                "observer",
                "approval",
            ]
        ) {
            try await ExecutionTesting
                .runToolCallResolverObserver()
        }

        diagnosticTest(
            "typed-agent-tool-contract",
            tags: [
                "agentic-execution",
                "tools",
                "typed",
                "erasure",
                "observations",
                "projection",
            ]
        ) {
            try await ExecutionTesting
                .runTypedAgentToolContract()
        }

        diagnosticTest(
            "tool-call-failure-envelope",
            tags: [
                "agentic-execution",
                "tools",
                "failure",
                "phase",
                "reported-failure",
                "persistence",
            ]
        ) {
            try await ExecutionTesting
                .runToolCallFailureEnvelope()
        }

        diagnosticTest(
            "tool-mechanical-observe-retry",
            tags: [
                "agentic-execution",
                "tools",
                "recovery",
                "retry",
                "observe",
            ]
        ) {
            try await ExecutionTesting
                .runToolMechanicalObserveRetry()
        }

        diagnosticTest(
            "tool-mechanical-mutation-recovery",
            tags: [
                "agentic-execution",
                "tools",
                "recovery",
                "reconciliation",
                "mutation",
            ]
        ) {
            try await ExecutionTesting
                .runToolMechanicalMutationRecovery()
        }

        diagnosticTest(
            "tool-invocation-recovery-evidence",
            tags: [
                "agentic-execution",
                "tools",
                "invocation",
                "recovery",
                "evidence",
                "persistence",
            ]
        ) {
            try await ExecutionTesting
                .runToolInvocationRecoveryEvidence()
        }

        diagnosticTest(
            "tool-plan-recovery-evidence",
            tags: [
                "agentic-execution",
                "tools",
                "tool-plan",
                "recovery",
                "evidence",
                "persistence",
            ]
        ) {
            try await ExecutionTesting
                .runToolPlanRecoveryEvidence()
        }

        diagnosticTest(
            "tool-reconciliation",
            tags: [
                "agentic-execution",
                "tools",
                "recovery",
                "reconciliation",
                "mutation",
            ]
        ) {
            try await ExecutionTesting
                .runToolReconciliation()
        }

    }

    private static func diagnosticTest(
        _ id: String,
        tags: Set<String>,
        operation: @escaping @Sendable () async throws -> [TestDiagnostic]
    ) -> Test {
        Test(
            id,
            tags: tags
        ) { context in
            await context.record(
                contentsOf: try await operation()
            )
        }
    }
}