import Foundation
import Workspace

public struct ToolInvoker: Sendable {
    public let registry: ToolRegistry
    public let policy: ToolExecutionPolicy
    public let recovery: Recovery.Policy?
    public let observationHandler:
        ToolExecutionObservations.Observer?

    public init(
        registry: ToolRegistry,
        policy: ToolExecutionPolicy,
        recovery: Recovery.Policy? = nil,
        observationHandler:
            ToolExecutionObservations.Observer? = nil
    ) {
        self.registry = registry
        self.policy = policy
        self.recovery = recovery
        self.observationHandler = observationHandler
    }

    public func review(
        _ invocation: ToolInvocation,
        context: ToolContext,
        references: [Reference] = []
    ) async throws -> ToolInvocation.Review {
        let context = try targetedContext(
            for: invocation,
            context: context
        )
        let preflight = try await registry.preflight(
            ToolCall(
                id: invocation.id,
                tool: invocation.tool,
                input: invocation.arguments
            ),
            context: context
        )

        return .init(
            invocation: invocation,
            preflight: preflight,
            requirement: policy.evaluate(
                preflight
            ),
            references: references
        )
    }

    public func invoke(
        _ invocation: ToolInvocation,
        context: ToolContext,
        references: [Reference] = [],
        approvalHandler: (any ToolApprovalHandler)? = nil
    ) async throws -> ToolInvocation.Result {
        let review = try await review(
            invocation,
            context: context,
            references: references
        )

        return try await invoke(
            review,
            context: context,
            approvalHandler: approvalHandler
        )
    }

    public func invoke(
        _ review: ToolInvocation.Review,
        context: ToolContext,
        approvalHandler: (any ToolApprovalHandler)? = nil
    ) async throws -> ToolInvocation.Result {
        let decision: ApprovalDecision

        switch review.requirement {
        case .no_approval_needed:
            decision = .approved

        case .needs_human_review:
            guard let approvalHandler else {
                return .init(
                    review: review,
                    outcome: .interrupted(
                        .human_review
                    )
                )
            }

            decision = try await approvalHandler.decide(
                on: review
            )

        case .denied_forbidden:
            decision = .denied
        }

        switch decision {
        case .approved:
            let invocation = review.invocation
            let context = try targetedContext(
                for: invocation,
                context: context
            )
            let execution = try await ToolExecutionEngine(
                registry: registry,
                recovery: recovery,
                context: context,
                observationHandler: observationHandler
            ).execute(
                ToolCall(
                    id: invocation.id,
                    tool: invocation.tool,
                    input: invocation.arguments
                ),
                preflight: review.preflight
            )

            return .init(
                review: review,
                outcome: .executed(
                    execution
                )
            )

        case .denied:
            return .init(
                review: review,
                outcome: .denied
            )

        case .skipped:
            return .init(
                review: review,
                outcome: .skipped
            )

        case .needshuman:
            return .init(
                review: review,
                outcome: .interrupted(
                    .human_review
                )
            )
        }
    }

    public func invoke(
        _ plan: ToolPlan,
        in context: ToolContext,
        references: [Reference] = [],
        approvalHandler: (any ToolApprovalHandler)? = nil
    ) async throws -> ToolPlan.Result {
        try await ToolPlanExecutor(
            invoker: self
        ).execute(
            plan,
            in: context,
            references: references,
            approvalHandler: approvalHandler
        )
    }
}

private extension ToolInvoker {
    func targetedContext(
        for invocation: ToolInvocation,
        context: ToolContext
    ) throws -> ToolContext {
        guard let target = invocation.execution?.workspace else {
            return context
        }

        guard let workspace = context.workspace else {
            throw WorkspaceToolTargetingError.workspaceRequired(
                invocation.tool.rawValue
            )
        }

        return context.using(
            workspace: try workspace.context(
                atRootPath: target.subpath
            )
        )
    }
}
