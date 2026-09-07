public struct AgentRequest: Sendable, Codable, Hashable {
    public var model: String?
    public var messages: [AgentMessage]
    public var tools: [AgentToolDefinition]
    public var generationConfiguration: AgentGenerationConfiguration
    public var invocationoptions: AgentModelInvocationOptions?
    public var metadata: [String: String]

    public init(
        model: String? = nil,
        messages: [AgentMessage],
        tools: [AgentToolDefinition] = [],
        generationConfiguration: AgentGenerationConfiguration = .default,
        invocationoptions: AgentModelInvocationOptions? = nil,
        metadata: [String: String] = [:]
    ) {
        self.model = model
        self.messages = messages
        self.tools = tools
        self.generationConfiguration = generationConfiguration
        self.invocationoptions = invocationoptions
        self.metadata = metadata
    }
}

