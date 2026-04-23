public struct AgentSkill: Sendable, Codable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let summary: String
    public let body: String

    public init(
        id: String,
        name: String,
        summary: String,
        body: String
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.body = body
    }
}
