public struct AgentModelProviderID: Sendable, Codable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public init(
        stringLiteral value: String
    ) {
        self.init(
            rawValue: value
        )
    }

    public init(
        _ value: String
    ) {
        self.init(
            rawValue: value
        )
    }
}

public struct AgentModelID: Sendable, Codable, Hashable {
    public var provider: AgentModelProviderID
    public var name: String

    public init(
        provider: AgentModelProviderID,
        name: String
    ) {
        self.provider = provider
        self.name = name
    }

    public var rawValue: String {
        "\(provider.rawValue):\(name)"
    }
}
