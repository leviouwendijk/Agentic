public struct AgentToolReference: Sendable, Codable, Hashable {
    public let identifier: AgentToolIdentifier
    public let owner: String?

    public init(
        identifier: AgentToolIdentifier,
        owner: String? = nil
    ) {
        self.identifier = identifier
        self.owner = owner
    }
}

public extension AgentToolReference {
    var name: String {
        identifier.rawValue
    }

    static func tool(
        _ identifier: AgentToolIdentifier,
        owner: String? = nil
    ) -> Self {
        .init(
            identifier: identifier,
            owner: owner
        )
    }

    static func tool(
        _ name: String,
        owner: String? = nil
    ) -> Self {
        .init(
            identifier: .init(name),
            owner: owner
        )
    }
}
