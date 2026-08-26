import Agentic
import Primitives
import TestFlows

extension AgenticFlowTesting {
    static func runToolResultProcessingNewStyle() async throws -> [TestFlowDiagnostic] {
        let execution = try await resultProcessingExecution(
            tool: ResultProcessingTool(),
            callID: "result-processing-new-style"
        )

        try Expect.equal(
            execution.result.output,
            execution.input,
            "new-style result preserves authoritative output"
        )

        guard
            let processing = execution.result.processing,
            let projection = processing.projection,
            let receipt = execution.result.receipt
        else {
            throw FlowTestError.unexpectedResult(
                "Expected new-style processing projection and compatibility receipt."
            )
        }

        try Expect.equal(
            projection.status,
            "passed",
            "new-style semantic status"
        )

        try Expect.equal(
            projection.summary,
            "Semantic projection.",
            "new-style semantic summary"
        )

        try Expect.equal(
            projection.facts.map(\.label),
            [
                "value"
            ],
            "new-style projection fact labels"
        )

        try Expect.equal(
            projection.facts.map(\.value),
            [
                "authoritative"
            ],
            "new-style projection fact values"
        )

        try Expect.equal(
            processing.observations.map(\.kind),
            [
                .standard_output,
                .standard_error,
            ],
            "new-style observation kinds"
        )

        try Expect.equal(
            processing.observations.map(\.content),
            [
                "raw stdout\n",
                "raw stderr\n",
            ],
            "new-style observations retain raw evidence"
        )

        try Expect.equal(
            receipt.status,
            projection.status,
            "compatibility receipt derives semantic status from projection"
        )

        try Expect.equal(
            receipt.items.map(\.label),
            [
                "value"
            ],
            "compatibility receipt contains projection facts only"
        )

        try Expect.equal(
            receipt.items.map(\.value),
            [
                "authoritative"
            ],
            "compatibility receipt derives projection fact values"
        )

        try Expect.true(
            !receipt.items.contains { item in
                item.value.contains("raw stdout")
                    || item.value.contains("raw stderr")
            },
            "raw observations do not leak into compatibility receipt"
        )

        return [
            .field(
                "projection",
                projection.status
            ),
            .field(
                "observations",
                "\(processing.observations.count)"
            ),
            .field(
                "receiptFacts",
                "\(receipt.items.count)"
            ),
        ]
    }

    static func runToolResultProcessingLegacyReceipt() async throws -> [TestFlowDiagnostic] {
        let execution = try await resultProcessingExecution(
            tool: LegacyResultReceiptTool(),
            callID: "result-processing-legacy-receipt"
        )

        try Expect.equal(
            execution.result.output,
            execution.input,
            "legacy result preserves authoritative output"
        )

        guard
            let processing = execution.result.processing,
            let projection = processing.projection,
            let receipt = execution.result.receipt
        else {
            throw FlowTestError.unexpectedResult(
                "Expected legacy receipt to bridge into processing projection."
            )
        }

        try Expect.equal(
            projection.status,
            "legacy",
            "legacy receipt status bridges into projection"
        )

        try Expect.equal(
            projection.facts.map(\.label),
            [
                "legacy"
            ],
            "legacy receipt item bridges into projection fact"
        )

        try Expect.equal(
            projection.facts.map(\.value),
            [
                "fact"
            ],
            "legacy receipt value bridges into projection fact"
        )

        try Expect.equal(
            processing.observations,
            [],
            "legacy receipt bridge manufactures no observations"
        )

        try Expect.equal(
            receipt.status,
            "legacy",
            "legacy receipt remains available during compatibility window"
        )

        return [
            .field(
                "projection",
                projection.status
            ),
            .field(
                "observations",
                "\(processing.observations.count)"
            ),
        ]
    }

    static func runToolResultProcessingPlain() async throws -> [TestFlowDiagnostic] {
        let execution = try await resultProcessingExecution(
            tool: PlainResultTool(),
            callID: "result-processing-plain"
        )

        try Expect.equal(
            execution.result.output,
            execution.input,
            "plain result preserves authoritative output"
        )

        try Expect.true(
            execution.result.processing == nil,
            "plain tool does not manufacture result processing"
        )

        try Expect.true(
            execution.result.receipt == nil,
            "plain tool does not manufacture compatibility receipt"
        )

        return [
            .field(
                "processing",
                execution.result.processing == nil
                    ? "none"
                    : "unexpected"
            ),
            .field(
                "receipt",
                execution.result.receipt == nil
                    ? "none"
                    : "unexpected"
            ),
        ]
    }
}

private struct ResultProcessingFixture:
    Sendable,
    Codable,
    Hashable
{
    let value: String
}

private struct ResultProcessingTool:
    AgentTool
{
    let identifier: AgentToolIdentifier =
        "result_processing_new_style"

    let description =
        "Proves semantic result processing and observation separation."

    let risk: ActionRisk =
        .observe

    func call(
        input: JSONValue,
        workspace _: AgentWorkspace?
    ) async throws -> JSONValue {
        input
    }

    func processResult(
        input _: JSONValue,
        output _: JSONValue,
        workspace _: AgentWorkspace?
    ) -> AgentToolResultProcessing {
        .init(
            projection: .init(
                status: "passed",
                summary: "Semantic projection.",
                facts: [
                    .init(
                        label: "value",
                        value: "authoritative"
                    )
                ]
            ),
            observations: [
                .init(
                    kind: .standard_output,
                    label: "stdout",
                    content: "raw stdout\n"
                ),
                .init(
                    kind: .standard_error,
                    label: "stderr",
                    content: "raw stderr\n"
                ),
            ]
        )
    }
}

private struct LegacyResultReceiptTool:
    AgentTool
{
    let identifier: AgentToolIdentifier =
        "result_processing_legacy_receipt"

    let description =
        "Proves legacy receipt compatibility bridging."

    let risk: ActionRisk =
        .observe

    func call(
        input: JSONValue,
        workspace _: AgentWorkspace?
    ) async throws -> JSONValue {
        input
    }

    func receipt(
        input _: JSONValue,
        output _: JSONValue,
        workspace _: AgentWorkspace?
    ) -> AgentToolReceipt? {
        .init(
            status: "legacy",
            summary: "Legacy receipt.",
            items: [
                .init(
                    label: "legacy",
                    value: "fact"
                )
            ]
        )
    }
}

private struct PlainResultTool:
    AgentTool
{
    let identifier: AgentToolIdentifier =
        "result_processing_plain"

    let description =
        "Proves an ordinary tool remains free of derived result processing."

    let risk: ActionRisk =
        .observe

    func call(
        input: JSONValue,
        workspace _: AgentWorkspace?
    ) async throws -> JSONValue {
        input
    }
}

private func resultProcessingExecution(
    tool: any AgentTool,
    callID: String
) async throws -> (
    input: JSONValue,
    result: AgentToolResult
) {
    let input = try JSONToolBridge.encode(
        ResultProcessingFixture(
            value: "authoritative"
        )
    )

    let registry = ToolRegistry(
        tools: [
            tool
        ]
    )

    let result = try await registry.execute(
        AgentToolCall(
            id: callID,
            name: tool.identifier.rawValue,
            input: input
        ),
        context: .init()
    )

    return (
        input: input,
        result: result
    )
}
