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

    static func tool<T>(
        _ type: T.Type,
        owner: String? = nil
    ) -> Self where T: AgentTool {
        .init(
            identifier: T.identifier,
            owner: owner
        )
    }
}
