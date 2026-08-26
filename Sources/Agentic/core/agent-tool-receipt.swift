public struct AgentToolReceipt:
    Sendable,
    Codable,
    Hashable
{
    public let status: String
    public let summary: String?
    public let items: [Item]

    public init(
        status: String,
        summary: String? = nil,
        items: [Item] = []
    ) {
        self.status = status
        self.summary = summary
        self.items = items
    }

    public struct Item:
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
