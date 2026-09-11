public struct AgentModelGatewayFactory:
    Sendable
{
    private let makeHandler:
        @Sendable () async throws -> any AgentModelGateway

    public init(
        make: @escaping @Sendable () async throws
            -> any AgentModelGateway
    ) {
        self.makeHandler = make
    }

    public func make() async throws
        -> any AgentModelGateway
    {
        try await makeHandler()
    }
}
