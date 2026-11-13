public struct AgentGenerationConfiguration: Sendable, Codable, Hashable {
    public var maxOutputTokens: Int?
    public var temperature: Double?
    public var topP: Double?
    public var stopSequences: [String]

    public init(
        maxOutputTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        stopSequences: [String] = []
    ) {
        self.maxOutputTokens = maxOutputTokens
        self.temperature = temperature
        self.topP = topP
        self.stopSequences = stopSequences
    }

    public static let `default` = Self()
}
