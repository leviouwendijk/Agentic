import Primitives

public struct AgentToolCollectionIdentifier:
    StringIdentifier
{
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }
}

public struct AgentToolCollectionMetadata:
    Sendable,
    Hashable
{
    public let identifier: AgentToolCollectionIdentifier
    public let title: String

    public init(
        identifier: AgentToolCollectionIdentifier,
        title: String
    ) {
        self.identifier = identifier
        self.title = title
    }

    public static let ungrouped = Self(
        identifier: .init(
            rawValue: "agentic.ungrouped"
        ),
        title: "Application"
    )
}
