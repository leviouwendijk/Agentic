import Agentic

public struct AgentAdvisorConfiguration: Sendable, Codable, Hashable {
    public var identifier: ToolIdentifier
    public var modelSelection: AgentModelSelection
    public var systemPrompt: String
    public var maxOutputTokens: Int?
    public var temperature: Double?

    public init(
        identifier: ToolIdentifier = AgentAdvisorDefaults.identifier,
        modelSelection: AgentModelSelection = .advisor,
        systemPrompt: String = AgentAdvisorDefaults.systemPrompt,
        maxOutputTokens: Int? = 900,
        temperature: Double? = 0.0
    ) {
        self.identifier = identifier
        self.modelSelection = modelSelection
        self.systemPrompt = systemPrompt
        self.maxOutputTokens = maxOutputTokens
        self.temperature = temperature
    }
}
