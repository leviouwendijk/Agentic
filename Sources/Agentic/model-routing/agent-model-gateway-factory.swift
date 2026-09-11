public enum AgentModelGatewayFactoryError:
    Error,
    Sendable,
    Equatable
{
    case identifierMismatch(
        expected: AgentModelGatewayIdentifier,
        actual: AgentModelGatewayIdentifier
    )
}

public struct AgentModelGatewayFactory:
    Sendable,
    Identifiable
{
    public let identifier: AgentModelGatewayIdentifier

    private let makeHandler:
        @Sendable () async throws -> any AgentModelGateway

    public init(
        identifier: AgentModelGatewayIdentifier,
        make: @escaping @Sendable () async throws
            -> any AgentModelGateway
    ) {
        self.identifier = identifier
        self.makeHandler = make
    }

    public var id: AgentModelGatewayIdentifier {
        identifier
    }

    public func make() async throws
        -> any AgentModelGateway
    {
        let gateway = try await makeHandler()

        guard gateway.identifier == identifier else {
            throw AgentModelGatewayFactoryError.identifierMismatch(
                expected: identifier,
                actual: gateway.identifier
            )
        }

        return gateway
    }
}
