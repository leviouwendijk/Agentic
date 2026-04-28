public struct AgentModelProfileIdentifier: Sendable, Codable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
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

public struct AgentModelAdapterIdentifier: Sendable, Codable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
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
