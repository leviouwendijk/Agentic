import Foundation
import Primitives
import Workspace

public enum FunctionCallResolutionError:
    Error,
    Sendable,
    LocalizedError
{
    case needsHumanReview(ToolInvocation.Review)
    case toolNotVisible(ToolIdentifier)

    public var errorDescription: String? {
        switch self {
        case .needsHumanReview:
            return "Tool invocation requires human review."

        case .toolNotVisible(let identifier):
            return "Tool '\(identifier.rawValue)' is not visible to the current Agent."
        }
    }
}

public struct GovernedFunctionCallResolver:
    FunctionCallResolver,
    Sendable
{
    public let registry: ToolRegistry
    public let visibleToolIdentifiers: Set<ToolIdentifier>
    public let tools: ToolExecutor
    public let context: ToolContext
    public let approvalHandler: (any ToolApprovalHandler)?
    public let resolutionObserver:
        (@Sendable (ToolInvocation.Result) async -> Void)?

    public init(
        registry: ToolRegistry,
        visibleToolIdentifiers: [ToolIdentifier],
        policy: ToolExecutionPolicy,
        recovery: Recovery.Policy? = nil,
        context: ToolContext = .init(),
        approvalHandler: (any ToolApprovalHandler)? = nil,
        observationHandler:
            ToolExecutionObservations.Observer? = nil,
        resolutionObserver:
            (@Sendable (ToolInvocation.Result) async -> Void)? = nil
    ) {
        self.registry = registry
        self.visibleToolIdentifiers = Set(
            visibleToolIdentifiers
        )
        self.tools = ToolExecutor(
            registry: registry,
            policy: policy,
            recovery: recovery,
            observationHandler: observationHandler
        )
        self.context = context
        self.approvalHandler = approvalHandler
        self.resolutionObserver = resolutionObserver
    }

    public func resolve(
        _ call: FunctionCall
    ) async throws -> ToolExecution.Response {
        guard visibleToolIdentifiers.contains(
            ToolIdentifier(call.name)
        ),
        registry.modelFacingDefinition(
            identifiedBy: ToolIdentifier(call.name)
        ) != nil
        else {
            throw FunctionCallResolutionError
                .toolNotVisible(
                    ToolIdentifier(call.name)
                )
        }

        let toolInvocation = try registry.invocation(
            for: call
        )
        let invocation = try await tools.invoke(
            toolInvocation,
            context: context,
            approvalHandler: approvalHandler
        )

        await resolutionObserver?(
            invocation
        )

        switch invocation.outcome {
        case .executed(let execution):
            return execution.result

        case .interrupted(.human_review):
            throw FunctionCallResolutionError.needsHumanReview(
                invocation.review
            )

        case .denied:
            return try deniedResult(
                for: call,
                review: invocation.review
            )

        case .skipped:
            return try skippedResult(
                for: call,
                review: invocation.review
            )
        }
    }
}

private extension GovernedFunctionCallResolver {
    struct ResolutionPayload:
        Sendable,
        Encodable
    {
        let kind: String
        let callID: String
        let toolName: String
        let requirement: String
        let summary: String
    }

    func deniedResult(
        for call: FunctionCall,
        review: ToolInvocation.Review
    ) throws -> ToolExecution.Response {
        ToolExecution.Response(
            call: call.reference,
            output: try JSONValue.encoding(
                ResolutionPayload(
                    kind: "tool_denied",
                    callID: call.id,
                    toolName: call.name,
                    requirement: review.requirement.rawValue,
                    summary: review.preflight.summary
                )
            ),
            isError: true
        )
    }

    func skippedResult(
        for call: FunctionCall,
        review: ToolInvocation.Review
    ) throws -> ToolExecution.Response {
        ToolExecution.Response(
            call: call.reference,
            output: try JSONValue.encoding(
                ResolutionPayload(
                    kind: "tool_skipped",
                    callID: call.id,
                    toolName: call.name,
                    requirement: review.requirement.rawValue,
                    summary: "Skipped explicitly by the operator."
                )
            ),
            isError: false
        )
    }
}