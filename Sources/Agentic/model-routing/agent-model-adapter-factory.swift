public struct AgentModelAdapterFactory:
    Sendable
{
    private let makeHandler:
        @Sendable () async throws -> any AgentModelAdapter

    public init(
        make: @escaping @Sendable () async throws
            -> any AgentModelAdapter
    ) {
        self.makeHandler = make
    }

    public func make() async throws
        -> any AgentModelAdapter
    {
        try await makeHandler()
    }
}
