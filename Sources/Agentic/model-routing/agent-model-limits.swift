public struct AgentModelLimits: Sendable, Codable, Hashable {
    public var inputTokens: Int?
    public var outputTokens: Int?

    public init(
        inputTokens: Int? = nil,
        outputTokens: Int? = nil
    ) {
        self.inputTokens = inputTokens.map {
            max(0, $0)
        }
        self.outputTokens = outputTokens.map {
            max(0, $0)
        }
    }

    public static let unknown = Self()
}
