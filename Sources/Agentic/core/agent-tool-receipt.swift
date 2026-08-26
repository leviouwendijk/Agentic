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

public extension AgentToolReceipt {
    init(
        _ projection: AgentToolResultProjection
    ) {
        self.init(
            status: projection.status,
            summary: projection.summary,
            items: projection.facts.map { fact in
                .init(
                    label: fact.label,
                    value: fact.value
                )
            }
        )
    }
}

public extension AgentToolResultProjection {
    init(
        _ receipt: AgentToolReceipt
    ) {
        self.init(
            status: receipt.status,
            summary: receipt.summary,
            facts: receipt.items.map { item in
                .init(
                    label: item.label,
                    value: item.value
                )
            }
        )
    }
}
