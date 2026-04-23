public struct LoadSkillToolOutput: Sendable, Codable, Hashable {
    public let id: String
    public let name: String
    public let summary: String
    public let content: String
    public let metadata: [String: String]?

    public init(
        id: String,
        name: String,
        summary: String,
        content: String,
        metadata: [String: String]?
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.content = content
        self.metadata = metadata
    }
}
