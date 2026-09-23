import Agentic

public struct AgentAdvisorConfiguration: Sendable, Codable, Hashable {
    public var modelSelection: AgentModelSelection
    public var systemPrompt: String
    public var maxOutputTokens: Int?
    public var temperature: Double?

    public init(
        modelSelection: AgentModelSelection = .advisor,
        systemPrompt: String = AgentAdvisorDefaults.systemPrompt,
        maxOutputTokens: Int? = 900,
        temperature: Double? = 0.0
    ) {
        self.modelSelection = modelSelection
        self.systemPrompt = systemPrompt
        self.maxOutputTokens = maxOutputTokens
        self.temperature = temperature
    }
}
