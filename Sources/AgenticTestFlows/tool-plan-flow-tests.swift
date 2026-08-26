import Agentic
import Primitives
import TestFlows

extension AgenticFlowTesting {
    static func runToolPlanSequenceStopsAfterFailure() async throws -> [TestFlowDiagnostic] {
        let probe = ToolPlanProbe()
        let invoker = toolPlanInvoker(
            probe: probe
        )

        let first = try toolPlanProbeCall(
            marker: "sequence-first"
        )

        let missing = try missingToolPlanCall(
            marker: "sequence-missing"
        )

        let never = try toolPlanProbeCall(
            marker: "sequence-never"
        )

        let result = try await invoker.invoke(
            AgentToolPlan(
                id: "sequence-stops-after-failure",
                root: .sequence(
                    [
                        .call(first),
                        .call(missing),
                        .call(never),
                    ]
                )
            )
        )

        try Expect.equal(
            result.outcome,
            .failed,
            "sequence outcome"
        )

        try Expect.equal(
            await probe.markers(),
            [
                "sequence-first",
            ],
            "sequence executed markers"
        )

        try Expect.equal(
            result.records.map(\.outcome),
            [
                .succeeded,
                .failed,
                .skipped,
            ],
            "sequence record outcomes"
        )

        return [
            .field(
                "outcome",
                result.outcome.rawValue
            ),
            .field(
                "records",
                "\(result.records.count)"
            ),
        ]
    }

    static func runToolPlanNestedSuccessRecursion() async throws -> [TestFlowDiagnostic] {
        let probe = ToolPlanProbe()
        let invoker = toolPlanInvoker(
            probe: probe
        )

        let a = try toolPlanProbeCall(
            marker: "a"
        )

        let a2 = try toolPlanProbeCall(
            marker: "a2"
        )

        let a2b = try toolPlanProbeCall(
            marker: "a2b"
        )

        let a3 = try toolPlanProbeCall(
            marker: "a3"
        )

        let result = try await invoker.invoke(
            AgentToolPlan(
                id: "nested-success-recursion",
                root: .call(
                    a,
                    onSuccess: [
                        .sequence(
                            [
                                .call(
                                    a2,
                                    onSuccess: [
                                        .call(
                                            a2b
                                        ),
                                    ]
                                ),
                                .call(
                                    a3
                                ),
                            ]
                        ),
                    ]
                )
            )
        )

        try Expect.equal(
            result.outcome,
            .succeeded,
            "nested plan outcome"
        )

        try Expect.equal(
            await probe.markers(),
            [
                "a",
                "a2",
                "a2b",
                "a3",
            ],
            "nested plan execution order"
        )

        try Expect.equal(
            result.records.map(\.call.id),
            [
                a.id,
                a2.id,
                a2b.id,
                a3.id,
            ],
            "nested plan record order"
        )

        try Expect.equal(
            result.records.map(\.outcome),
            [
                .succeeded,
                .succeeded,
                .succeeded,
                .succeeded,
            ],
            "nested plan record outcomes"
        )

        return [
            .field(
                "outcome",
                result.outcome.rawValue
            ),
            .field(
                "executed",
                "\(result.executedCount)"
            ),
        ]
    }

    static func runToolPlanBatchContinuesIndependentSiblings() async throws -> [TestFlowDiagnostic] {
        let probe = ToolPlanProbe()
        let invoker = toolPlanInvoker(
            probe: probe
        )

        let first = try toolPlanProbeCall(
            marker: "batch-first"
        )

        let missing = try missingToolPlanCall(
            marker: "batch-missing"
        )

        let third = try toolPlanProbeCall(
            marker: "batch-third"
        )

        let result = try await invoker.invoke(
            AgentToolPlan(
                id: "batch-continues-independent-siblings",
                root: .batch(
                    [
                        .call(first),
                        .call(missing),
                        .call(third),
                    ]
                )
            )
        )

        try Expect.equal(
            result.outcome,
            .mixed,
            "batch outcome"
        )

        try Expect.equal(
            await probe.markers(),
            [
                "batch-first",
                "batch-third",
            ],
            "batch executed markers"
        )

        try Expect.equal(
            result.records.map(\.outcome),
            [
                .succeeded,
                .failed,
                .succeeded,
            ],
            "batch record outcomes"
        )

        return [
            .field(
                "outcome",
                result.outcome.rawValue
            ),
            .field(
                "executed",
                "\(result.executedCount)"
            ),
        ]
    }
}

private actor ToolPlanProbe {
    private var recorded: [String] = []

    func record(
        _ marker: String
    ) {
        recorded.append(
            marker
        )
    }

    func markers() -> [String] {
        recorded
    }
}

private struct ToolPlanProbeTool:
    AgentTool
{
    let identifier: AgentToolIdentifier =
        "tool_plan_probe"

    let description =
        "Records governed tool-plan execution order."

    let risk: ActionRisk =
        .observe

    let probe: ToolPlanProbe

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
        context _: AgentToolExecutionContext
    ) async throws -> JSONValue {
        let decoded = try JSONToolBridge.decode(
            ToolPlanProbeValue.self,
            from: input
        )

        await probe.record(
            decoded.marker
        )

        return try JSONToolBridge.encode(
            decoded
        )
    }
}

private struct ToolPlanProbeValue:
    Sendable,
    Codable,
    Hashable
{
    let marker: String
}

private func toolPlanInvoker(
    probe: ToolPlanProbe
) -> ToolInvoker {
    ToolInvoker(
        registry: .init(
            tools: [
                ToolPlanProbeTool(
                    probe: probe
                ),
            ]
        ),
        policy: .init(
            autonomyMode: .auto_observe
        )
    )
}

private func toolPlanProbeCall(
    marker: String
) throws -> AgentToolCall {
    AgentToolCall(
        id: "tool-plan-\(marker)",
        name: "tool_plan_probe",
        input: try JSONToolBridge.encode(
            ToolPlanProbeValue(
                marker: marker
            )
        )
    )
}

private func missingToolPlanCall(
    marker: String
) throws -> AgentToolCall {
    AgentToolCall(
        id: "tool-plan-\(marker)",
        name: "tool_plan_missing",
        input: try JSONToolBridge.encode(
            ToolPlanProbeValue(
                marker: marker
            )
        )
    )
}
