import Tokens

public struct AgentCostUsage: Sendable, Codable, Hashable {
    public var inputTokens: Int
    public var outputTokens: Int
    public var cachedInputReadTokens: Int
    public var cachedInputWriteTokens: Int
    public var reasoningOutputTokens: Int
    public var requestCount: Int
    public var metadata: [String: String]

    public init(
        inputTokens: Int = 0,
        outputTokens: Int = 0,
        cachedInputReadTokens: Int = 0,
        cachedInputWriteTokens: Int = 0,
        reasoningOutputTokens: Int = 0,
        requestCount: Int = 1,
        metadata: [String: String] = [:]
    ) {
        self.inputTokens = max(
            0,
            inputTokens
        )
        self.outputTokens = max(
            0,
            outputTokens
        )
        self.cachedInputReadTokens = max(
            0,
            cachedInputReadTokens
        )
        self.cachedInputWriteTokens = max(
            0,
            cachedInputWriteTokens
        )
        self.reasoningOutputTokens = max(
            0,
            reasoningOutputTokens
        )
        self.requestCount = max(
            0,
            requestCount
        )
        self.metadata = metadata
    }

    public init(
        providerUsage: AgentUsage,
        requestCount: Int = 1,
        metadata: [String: String] = [:]
    ) {
        self.init(
            inputTokens: providerUsage.inputTokens ?? 0,
            outputTokens: providerUsage.outputTokens ?? 0,
            requestCount: requestCount,
            metadata: metadata
        )
    }

    public init(
        inputEstimate: TokenEstimate,
        reservedOutputTokens: Int = 0,
        requestCount: Int = 1,
        metadata: [String: String] = [:]
    ) {
        self.init(
            inputTokens: inputEstimate.estimatedTokens,
            outputTokens: reservedOutputTokens,
            requestCount: requestCount,
            metadata: metadata
        )
    }

    public var totalKnownTokens: Int {
        inputTokens
            + outputTokens
            + cachedInputReadTokens
            + cachedInputWriteTokens
            + reasoningOutputTokens
    }
}
