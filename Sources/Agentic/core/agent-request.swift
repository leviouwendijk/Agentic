public struct AgentRequest: Sendable, Codable, Hashable {
    public var messages: [Message]
    public var tools: [ToolDescriptor]
    public var generationConfiguration: AgentGenerationConfiguration
    public var responseFormat: AgentResponseFormat
    public var invocationoptions: AgentModelInvocationOptions?
    public var metadata: [String: String]

    public init(
        messages: [Message],
        tools: [ToolDescriptor] = [],
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
