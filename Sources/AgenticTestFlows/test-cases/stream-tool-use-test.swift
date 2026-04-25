import Agentic
import Primitives
import TestFlows

extension AgenticFlowTesting {
    static func runStreamToolUse() async throws -> [TestFlowDiagnostic] {
        let toolCall = AgentToolCall(
            id: "flowtest-tool-call-1",
            name: EchoTool.identifier.rawValue,
            input: try JSONToolBridge.encode(
                EchoToolInput(
                    text: "tool payload"
                )
            )
        )

        let firstResponse = AgentResponse(
            message: .init(
                role: .assistant,
                content: .init(
                    blocks: [
                        .text("need tool "),
                        .tool_call(toolCall)
                    ]
                )
            ),
            stopReason: .tool_use,
            usage: .init(
                inputTokens: 3,
                outputTokens: 2,
                totalTokens: 5
            ),
            metadata: [
                "source": "flowtest"
            ]
        )

        let finalResponse = response(
            text: "tool use ok",
            stopReason: .end_turn
        )

        let harness = try await FlowHarness(
            name: AgenticFlowSuite.ID.stream_tool_use,
            delivery: .stream,
            maximumIterations: 2,
            adapter: .stream(
                batches: [
                    .init(
                        events: [
                            .messagedelta(.text("need tool ")),
                            .toolcall(toolCall),
                            .completed(firstResponse),
                        ]
                    ),
                    .init(
                        events: [
                            .completed(finalResponse)
                        ]
                    ),
                ]
            ),
            toolRegistry: .init(
                tools: [
                    EchoTool()
                ]
            )
        )

        let result = try await harness.runner.run(
            request(),
            sessionID: harness.sessionID
        )
        let checkpoint = try await harness.checkpoint()

        try assertCompleted(
            result: result,
            checkpoint: checkpoint,
            expectedText: "tool use ok",
            expectedEvents: [
                .model_stream_started,
                .assistant_delta,
                .model_stream_tool_call,
                .model_stream_completed,
                .assistant_response,
                .tool_preflight,
                .tool_approved,
                .tool_result,
                .model_stream_started,
                .model_stream_completed,
                .assistant_response
            ]
        )

        return flowDiagnostics(
            response: "tool use ok",
            checkpoint: checkpoint,
            events: result.events
        )
    }
}
