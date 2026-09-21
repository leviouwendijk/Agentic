import Agentic
import Primitives
import TestFlows

extension AgenticFlowTesting {
    static func runToolInvokerReviewDoesNotExecute() async throws -> [TestFlowDiagnostic] {
        let probe = ToolInvocationProbe()
        let invoker = toolInvocationProbeInvoker(
            risk: .observe,
            autonomyMode: .auto_observe,
            probe: probe
        )
        let call = try toolInvocationProbeCall(
            marker: "review-only"
        )

        let review = try await invoker.review(
            call,
            context: .init(
                sessionID: "review-only-session"
            )
        )

        let callCount = await probe.count()

        try Expect.equal(
            review.call,
            call,
            "review retains exact tool call"
        )

        try Expect.equal(
            review.requirement,
            .no_approval_needed,
            "observe review is automatically allowed"
        )

        try Expect.equal(
            callCount,
            0,
            "review does not execute tool"
        )

        return [
            .field(
                "requirement",
                review.requirement.rawValue
            ),
            .field(
                "executions",
                "\(callCount)"
            )
        ]
    }

    static func runToolInvokerAutoObserveExecutes() async throws -> [TestFlowDiagnostic] {
        let probe = ToolInvocationProbe()
        let invoker = toolInvocationProbeInvoker(
            risk: .observe,
            autonomyMode: .auto_observe,
            probe: probe
        )
        let call = try toolInvocationProbeCall(
            marker: "auto-observe"
        )

        let invocation = try await invoker.invoke(
            call,
            context: .init(
                sessionID: "auto-observe-session"
            )
        )

        let toolResult = try requireToolInvocationResult(
            invocation
        )
        let output = try JSONToolBridge.decode(
            ToolInvocationProbeOutput.self,
            from: toolResult.output
        )
        let callCount = await probe.count()

        try Expect.equal(
            invocation.decision,
            .approved,
            "auto-observe invocation approved"
        )

        try Expect.equal(
            invocation.executed,
            true,
            "auto-observe invocation reports execution"
        )

        try Expect.equal(
            callCount,
            1,
            "auto-observe executes exactly once"
        )

        try Expect.equal(
            toolResult.toolCallID,
            call.id,
            "host invocation preserves tool call id"
        )

        try Expect.equal(
            output.toolCallID,
            call.id,
            "tool receives exact tool call id"
        )

        try Expect.equal(
            output.executionMode,
            AgentToolExecutionMode.host_call.rawValue,
            "default invocation uses host_call execution mode"
        )

        try Expect.equal(
            output.sessionID,
            "auto-observe-session",
            "host invocation forwards session id"
        )

        return [
            .field(
                "decision",
                invocation.decision.rawValue
            ),
            .field(
                "execution_mode",
                output.executionMode
            ),
            .field(
                "executions",
                "\(callCount)"
            )
        ]
    }

    static func runToolInvokerReviewWithoutHandlerDoesNotExecute() async throws -> [TestFlowDiagnostic] {
        let probe = ToolInvocationProbe()
        let invoker = toolInvocationProbeInvoker(
            risk: .boundedmutate,
            autonomyMode: .auto_observe,
            probe: probe
        )
        let call = try toolInvocationProbeCall(
            marker: "review-required"
        )

        let invocation = try await invoker.invoke(
            call
        )
        let callCount = await probe.count()

        try Expect.equal(
            invocation.review.requirement,
            .needs_human_review,
            "bounded mutation requires review under auto_observe"
        )

        try Expect.equal(
            invocation.decision,
            .needshuman,
            "missing approval handler leaves invocation pending human review"
        )

        try Expect.isNil(
            invocation.toolResult,
            "review-required invocation has no tool result before approval"
        )

        try Expect.equal(
            callCount,
            0,
            "review-required invocation does not execute without handler"
        )

        return [
            .field(
                "requirement",
                invocation.review.requirement.rawValue
            ),
            .field(
                "decision",
                invocation.decision.rawValue
            ),
            .field(
                "executions",
                "\(callCount)"
            )
        ]
    }

    static func runToolInvokerApprovedHostCallExecutes() async throws -> [TestFlowDiagnostic] {
        let probe = ToolInvocationProbe()
        let invoker = toolInvocationProbeInvoker(
            risk: .boundedmutate,
            autonomyMode: .auto_observe,
            probe: probe
        )
        let call = try toolInvocationProbeCall(
            marker: "approved-host"
        )

        let invocation = try await invoker.invoke(
            call,
            context: .init(
                sessionID: "approved-host-session",
                metadata: [
                    "source": "web-bridge-test"
                ]
            ),
            approvalHandler: StaticToolApprovalHandler(
                decision: .approved
            )
        )

        let toolResult = try requireToolInvocationResult(
            invocation
        )
        let output = try JSONToolBridge.decode(
            ToolInvocationProbeOutput.self,
            from: toolResult.output
        )
        let callCount = await probe.count()

        try Expect.equal(
            invocation.review.requirement,
            .needs_human_review,
            "bounded mutation enters human review"
        )

        try Expect.equal(
            invocation.decision,
            .approved,
            "approval handler approves host invocation"
        )

        try Expect.equal(
            callCount,
            1,
            "approved host invocation executes exactly once"
        )

        try Expect.equal(
            output.toolCallID,
            call.id,
            "approved host invocation forwards tool call id"
        )

        try Expect.equal(
            output.executionMode,
            AgentToolExecutionMode.host_call.rawValue,
            "approved invocation remains host_call"
        )

        try Expect.equal(
            output.sessionID,
            "approved-host-session",
            "approved invocation forwards session"
        )

        try Expect.equal(
            output.metadataSource,
            "web-bridge-test",
            "approved invocation forwards metadata"
        )

        return [
            .field(
                "decision",
                invocation.decision.rawValue
            ),
            .field(
                "execution_mode",
                output.executionMode
            ),
            .field(
                "metadata_source",
                output.metadataSource ?? "<nil>"
            )
        ]
    }

    static func runToolInvokerDeniedHostCallDoesNotExecute() async throws -> [TestFlowDiagnostic] {
        let probe = ToolInvocationProbe()
        let invoker = toolInvocationProbeInvoker(
            risk: .boundedmutate,
            autonomyMode: .auto_observe,
            probe: probe
        )
        let call = try toolInvocationProbeCall(
            marker: "denied-host"
        )

        let invocation = try await invoker.invoke(
            call,
            approvalHandler: StaticToolApprovalHandler(
                decision: .denied
            )
        )
        let callCount = await probe.count()

        try Expect.equal(
            invocation.review.requirement,
            .needs_human_review,
            "denied invocation first requires human review"
        )

        try Expect.equal(
            invocation.decision,
            .denied,
            "approval handler denial is preserved"
        )

        try Expect.isNil(
            invocation.toolResult,
            "denied invocation has no tool result"
        )

        try Expect.equal(
            callCount,
            0,
            "denied invocation never executes"
        )

        return [
            .field(
                "decision",
                invocation.decision.rawValue
            ),
            .field(
                "executions",
                "\(callCount)"
            )
        ]
    }

    static func runToolInvokerForbiddenNeverExecutes() async throws -> [TestFlowDiagnostic] {
        let probe = ToolInvocationProbe()
        let invoker = toolInvocationProbeInvoker(
            risk: .forbidden,
            autonomyMode: .review_privileged,
            probe: probe
        )
        let call = try toolInvocationProbeCall(
            marker: "forbidden"
        )

        let invocation = try await invoker.invoke(
            call,
            approvalHandler: StaticToolApprovalHandler(
                decision: .approved
            )
        )
        let callCount = await probe.count()

        try Expect.equal(
            invocation.review.requirement,
            .denied_forbidden,
            "forbidden action is denied by policy"
        )

        try Expect.equal(
            invocation.decision,
            .denied,
            "forbidden action cannot be approved by host handler"
        )

        try Expect.isNil(
            invocation.toolResult,
            "forbidden invocation has no tool result"
        )

        try Expect.equal(
            callCount,
            0,
            "forbidden invocation never executes"
        )

        return [
            .field(
                "requirement",
                invocation.review.requirement.rawValue
            ),
            .field(
                "decision",
                invocation.decision.rawValue
            ),
            .field(
                "executions",
                "\(callCount)"
            )
        ]
    }
}

private actor ToolInvocationProbe {
    private var callCount = 0

    func recordExecution() {
        callCount += 1
    }

    func count() -> Int {
        callCount
    }
}

private struct ToolInvocationProbeTool: AgentTool {
    let identifier: AgentToolIdentifier = "tool_invocation_probe"
    let description = "Records one governed tool invocation."
    let risk: ActionRisk
    let probe: ToolInvocationProbe

    func preflight(
        input _: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        ToolPreflight(
            toolName: identifier.rawValue,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            summary: description
        )
    }

    func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        try await call(
            input: input,
            context: .init(
                workspace: workspace
            )
        )
    }

    func call(
        input: JSONValue,
        context: AgentToolExecutionContext
    ) async throws -> JSONValue {
        let decoded = try JSONToolBridge.decode(
            ToolInvocationProbeInput.self,
            from: input
        )

        await probe.recordExecution()

        return try JSONToolBridge.encode(
            ToolInvocationProbeOutput(
                marker: decoded.marker,
                toolCallID: context.toolCallID,
                executionMode: context.executionMode.rawValue,
                sessionID: context.sessionID,
                metadataSource: context.metadata["source"]
            )
        )
    }
}

private struct ToolInvocationProbeInput: Sendable, Codable, Hashable {
    var marker: String
}

private struct ToolInvocationProbeOutput: Sendable, Codable, Hashable {
    var marker: String
    var toolCallID: String?
    var executionMode: String
    var sessionID: String?
    var metadataSource: String?
}

private struct StaticToolApprovalHandler: ToolApprovalHandler {
    let decision: ApprovalDecision

    func decide(
        on _: ToolPreflight,
        requirement _: ApprovalRequirement
    ) async throws -> ApprovalDecision {
        decision
    }
}

private func toolInvocationProbeInvoker(
    risk: ActionRisk,
    autonomyMode: AutonomyMode,
    probe: ToolInvocationProbe
) -> ToolInvoker {
    ToolInvoker(
        registry: .init(
            tools: [
                ToolInvocationProbeTool(
                    risk: risk,
                    probe: probe
                )
            ]
        ),
        policy: .init(
            autonomyMode: autonomyMode
        )
    )
}

private func toolInvocationProbeCall(
    marker: String
) throws -> AgentToolCall {
    AgentToolCall(
        id: "tool-invocation-\(marker)",
        name: "tool_invocation_probe",
        input: try JSONToolBridge.encode(
            ToolInvocationProbeInput(
                marker: marker
            )
        )
    )
}

private func requireToolInvocationResult(
    _ invocation: ToolInvocation.Result
) throws -> AgentToolResult {
    guard let toolResult = invocation.toolResult else {
        throw FlowTestError.unexpectedResult(
            "Expected governed tool invocation to execute."
        )
    }

    return toolResult
}
