import Macros
import Primitives

public enum AgentModelGatewayResolution:
    Sendable
{
    case available(any AgentModelGateway)
    case unavailable(AgentModelGatewayUnavailability)
}

public struct AgentModelGatewayUnavailability:
    Sendable,
    Codable,
    Hashable
{
    public let kind: Kind
    public let message: String?
    public let metadata: [String: String]

    public init(
        kind: Kind,
        message: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.kind = kind
        self.message = message
        self.metadata = metadata
    }
}

public extension AgentModelGatewayUnavailability {
    struct Kind:
        StringIdentifier
    {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}

@StringIdentifiers
public extension AgentModelGatewayUnavailability.Kind {
    static var missing_configuration: Self
    static var invalid_configuration: Self
    static var unavailable_environment: Self
    static var provider_unavailable: Self
}
