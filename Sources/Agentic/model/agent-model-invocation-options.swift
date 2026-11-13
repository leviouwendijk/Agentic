public struct AgentModelInvocationOptions:
    Sendable,
    Codable,
    Hashable
{
    public var timeoutseconds: Int?

    public init(
        timeoutseconds: Int? = nil
    ) {
        self.timeoutseconds = timeoutseconds
    }

    public static let `default` = Self()
}
