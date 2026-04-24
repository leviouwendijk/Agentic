import TestFlows

enum AgenticFlowSuite: TestFlowRegistry {
    static let title = "Agentic flow tests"

    static let flows: [TestFlow] = [
        TestFlow(
            ID.buffered,
            tags: ["agentic", "buffered"]
        ) {
            try await AgenticFlowTesting.runBuffered()
        },

        TestFlow(
            ID.stream,
            tags: ["agentic", "stream"]
        ) {
            try await AgenticFlowTesting.runStream()
        },

        TestFlow(
            ID.stream_error,
            tags: ["agentic", "stream", "error"]
        ) {
            try await AgenticFlowTesting.runStreamError()
        },

        TestFlow(
            ID.stream_cancel,
            tags: ["agentic", "stream", "cancel"]
        ) {
            try await AgenticFlowTesting.runStreamCancel()
        },

        TestFlow(
            ID.stream_tool_use,
            tags: ["agentic", "stream", "tool-use"]
        ) {
            try await AgenticFlowTesting.runStreamToolUse()
        },
    ]
}

extension AgenticFlowSuite {
    enum ID {
        static let buffered = "buffered"
        static let stream = "stream"
        static let stream_error = "stream-error"
        static let stream_cancel = "stream-cancel"
        static let stream_tool_use = "stream-tool-use"
    }
}
