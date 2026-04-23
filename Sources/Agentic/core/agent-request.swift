public struct AgentRequest: Sendable, Codable, Hashable {
    public var model: String?
    public var messages: [AgentMessage]
    public var tools: [AgentToolDefinition]
    public var generationConfiguration: AgentGenerationConfiguration
    public var metadata: [String: String]

    public init(
        model: String? = nil,
        messages: [AgentMessage],
        tools: [AgentToolDefinition] = [],
        generationConfiguration: AgentGenerationConfiguration = .default,
        metadata: [String: String] = [:]
    ) {
        self.model = model
        self.messages = messages
        self.tools = tools
        self.generationConfiguration = generationConfiguration
        self.metadata = metadata
    }
}
