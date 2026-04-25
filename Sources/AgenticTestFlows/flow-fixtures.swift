import Agentic
import Foundation

extension AgenticFlowTesting {
    static func request() -> AgentRequest {
        AgentRequest(
            model: "mock",
            messages: [
                .init(
                    role: .user,
                    text: "Run Agentic flow test."
                )
            ]
        )
    }

    static func response(
        text: String,
        stopReason: AgentStopReason
    ) -> AgentResponse {
        .init(
            message: .init(
                role: .assistant,
                text: text
            ),
            stopReason: stopReason,
            usage: .init(
                inputTokens: 3,
                outputTokens: 2,
                totalTokens: 5
            ),
            metadata: [
                "source": "flowtest"
            ]
        )
    }
}
