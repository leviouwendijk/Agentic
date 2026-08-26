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
            let projection = processing.projection
        else {
            throw FlowTestError.unexpectedResult(
                "Expected new-style processing projection."
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

        try Expect.true(
            !projection.facts.contains { fact in
                fact.value.contains("raw stdout")
                    || fact.value.contains("raw stderr")
            },
            "raw observations do not leak into semantic projection"
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

        return [
            .field(
                "processing",
                execution.result.processing == nil
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
