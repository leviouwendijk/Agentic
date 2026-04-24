import Tokens

public struct AgentResponse: Sendable, Codable, Hashable {
    public let message: AgentMessage
    public let stopReason: AgentStopReason
    public let usage: AgentUsage?
    public let metadata: [String: String]

    public init(
        message: AgentMessage,
        stopReason: AgentStopReason,
        usage: AgentUsage? = nil,
        metadata: [String: String] = [:]
    ) {
        self.message = message
        self.stopReason = stopReason
        self.usage = usage
        self.metadata = metadata
    }
}

public extension AgentResponse {
    func estimatedOutputCostUsage(
        options: TokenEstimationOptions = .conservative,
        requestCount: Int = 0
    ) -> AgentCostUsage {
        .init(
            outputTokens: estimatedOutputTokens(
                options: options
            ).estimatedTokens,
            requestCount: requestCount,
            metadata: [
                "source": "agent_response"
            ]
        )
    }

    func estimatedOutputTokens(
        options: TokenEstimationOptions = .conservative
    ) -> TokenEstimate {
        TokenEstimator.estimate(
            message.content.text,
            options: options,
            source: "agent_response"
        )
    }
}
