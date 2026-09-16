public enum AgentModelGatewayFactoryError:
    Error,
    Sendable,
    Equatable
{
    case identifierMismatch(
        expected: AgentModelGatewayIdentifier,
        actual: AgentModelGatewayIdentifier
    )

    case unavailable(
        identifier: AgentModelGatewayIdentifier,
        reason: AgentModelGatewayUnavailability
    )
}

public struct AgentModelGatewayFactory:
    Sendable,
    Identifiable
{
    public let identifier: AgentModelGatewayIdentifier

    private let resolveHandler:
        @Sendable () async throws -> AgentModelGatewayResolution

    public init(
        identifier: AgentModelGatewayIdentifier,
        resolve: @escaping @Sendable () async throws
            -> AgentModelGatewayResolution
    ) {
        self.identifier = identifier
        self.resolveHandler = resolve
    }

    public init(
        identifier: AgentModelGatewayIdentifier,
        make: @escaping @Sendable () async throws
            -> any AgentModelGateway
    ) {
        self.init(
            identifier: identifier
        ) {
            .available(
                try await make()
            )
        }
    }

    public var id: AgentModelGatewayIdentifier {
        identifier
    }

    public func resolve() async throws
        -> AgentModelGatewayResolution
    {
        let resolution = try await resolveHandler()

        switch resolution {
        case .available(let gateway):
            guard gateway.identifier == identifier else {
                throw AgentModelGatewayFactoryError.identifierMismatch(
                    expected: identifier,
                    actual: gateway.identifier
                )
            }

            return .available(
                gateway
            )

        case .unavailable:
            return resolution
        }
    }

    public func make() async throws
        -> any AgentModelGateway
    {
        switch try await resolve() {
        case .available(let gateway):
            return gateway

        case .unavailable(let reason):
            throw AgentModelGatewayFactoryError.unavailable(
                identifier: identifier,
                reason: reason
            )
        }
    }
}
