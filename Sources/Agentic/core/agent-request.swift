public struct AgentRequest: Sendable, Codable, Hashable {
    public var messages: [AgentMessage]
    public var tools: [AgentToolDefinition]
    public var generationConfiguration: AgentGenerationConfiguration
    public var responseFormat: AgentResponseFormat
    public var invocationoptions: AgentModelInvocationOptions?
    public var metadata: [String: String]

    public init(
        messages: [AgentMessage],
        tools: [AgentToolDefinition] = [],
        generationConfiguration: AgentGenerationConfiguration = .default,
        responseFormat: AgentResponseFormat = .text,
        invocationoptions: AgentModelInvocationOptions? = nil,
        metadata: [String: String] = [:]
    ) {
        self.messages = messages
        self.tools = tools
        self.generationConfiguration = generationConfiguration
        self.responseFormat = responseFormat
        self.invocationoptions = invocationoptions
        self.metadata = metadata
    }
}
