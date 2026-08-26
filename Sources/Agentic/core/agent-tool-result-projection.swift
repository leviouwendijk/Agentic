public struct AgentToolResultProjection:
    Sendable,
    Codable,
    Hashable
{
    public let status: String
    public let summary: String?
    public let facts: [Fact]

    public init(
        status: String,
        summary: String? = nil,
        facts: [Fact] = []
    ) {
        self.status = status
        self.summary = summary
        self.facts = facts
    }

    public struct Fact:
        Sendable,
        Codable,
        Hashable
    {
        public let label: String
        public let value: String

        public init(
            label: String,
            value: String
        ) {
            self.label = label
            self.value = value
        }
    }
}
