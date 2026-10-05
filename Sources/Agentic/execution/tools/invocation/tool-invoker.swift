import Foundation
import Workspace

public struct ToolInvoker: Sendable {
    public let registry: ToolRegistry
    public let policy: ToolExecutionPolicy
    public let recovery: Recovery.Policy?

    public init(
        registry: ToolRegistry,
        policy: ToolExecutionPolicy,
        recovery: Recovery.Policy? = nil
    ) {
        self.registry = registry
        self.policy = policy
        self.recovery = recovery
    }

    public func review(
        _ call: ToolCall,
        execution: ToolInvocation.Execution? = nil,
        workspace: WorkspaceContext? = nil,
        references: [Reference] = []
    ) async throws -> ToolInvocation.Review {
        try await review(
            call,
            execution: execution,
            context: .init(
                workspace: workspace
            ),
            references: references
        )
    }

    public func review(
        _ call: ToolCall,
        execution: ToolInvocation.Execution? = nil,
        context: ToolContext,
        references: [Reference] = []
    ) async throws -> ToolInvocation.Review {
        let context = try targetedContext(
            for: call,
            execution: execution,
            context: context
        )

        let preflight = try await registry.preflight(
            call,
            context: context
        )

        return .init(
            call: call,
            preflight: preflight,
            requirement: policy.evaluate(
                preflight
            ),
            references: references
        )
    }

    public func invoke(
        _ call: ToolCall,
        execution: ToolInvocation.Execution? = nil,
        workspace: WorkspaceContext? = nil,
        references: [Reference] = [],
        approvalHandler: (any ToolApprovalHandler)? = nil
    ) async throws -> ToolInvocation.Result {
        try await invoke(
            call,
            execution: execution,
            context: .init(
                workspace: workspace
            ),
            references: references,
            approvalHandler: approvalHandler
        )
    }

    public func invoke(
        _ call: ToolCall,
        execution: ToolInvocation.Execution? = nil,
        context: ToolContext,
        references: [Reference] = [],
        approvalHandler: (any ToolApprovalHandler)? = nil
    ) async throws -> ToolInvocation.Result {
        let context = try targetedContext(
            for: call,
            execution: execution,
            context: context
        )

        let review = try await review(
            call,
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
        workspace: WorkspaceContext? = nil,
        approvalHandler: (any ToolApprovalHandler)? = nil
    ) async throws -> ToolInvocation.Result {
        try await invoke(
            review,
            context: .init(
                workspace: workspace
            ),
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
            let execution = try await ToolExecution(
                registry: registry,
                recovery: recovery,
                context: context
            ).execute(
                review.call,
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
        workspace: WorkspaceContext? = nil,
        references: [Reference] = [],
        approvalHandler: (any ToolApprovalHandler)? = nil
    ) async throws -> ToolPlan.Result {
        try await ToolPlanExecutor(
            invoker: self
        ).execute(
            plan,
            workspace: workspace,
            references: references,
            approvalHandler: approvalHandler
        )
    }
}

private extension ToolInvoker {
    func targetedContext(
        for call: ToolCall,
        execution: ToolInvocation.Execution?,
        context: ToolContext
    ) throws -> ToolContext {
        guard let target = execution?.workspace else {
            return context
        }

        guard let tool = registry.registeredTool(
            identifiedBy: call.tool
        ) else {
            throw ToolRegistryExecutionError.missingTool(
                call.tool.rawValue
            )
        }

        guard
            tool.capability.execution.workingLocation
                == AgentToolExecutionContract.WorkingLocation.targetable
        else {
            throw WorkspaceToolTargetingError.unsupportedTool(
                call.tool.rawValue
            )
        }

        guard let workspace = context.workspace else {
            throw WorkspaceToolTargetingError.workspaceRequired(
                call.tool.rawValue
            )
        }

        let subpath = target.subpath.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !subpath.isEmpty else {
            throw WorkspaceToolTargetingError.emptySubpath
        }

        return context.using(
            workspace: try workspace.context(
                atRootPath: subpath
            )
        )
    }
}
