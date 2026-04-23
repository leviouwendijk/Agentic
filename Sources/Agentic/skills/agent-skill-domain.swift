public struct AgentSkillDomain: Sendable, Codable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public init(
        _ rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public init(
        stringLiteral value: String
    ) {
        self.rawValue = value
    }
}

public extension AgentSkillDomain {
    static let core: Self = "core"
    static let swift: Self = "swift"
    static let web: Self = "web"
    static let writing: Self = "writing"
}
