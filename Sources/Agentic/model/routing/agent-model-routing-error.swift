import Foundation

public enum AgentModelRoutingError: Error, Sendable, LocalizedError {
    case emptyIdentifier(String)
    case emptyModel(AgentModelProfileIdentifier)
    case profileNotFound(AgentModelProfileIdentifier)
    case profileUnavailable(
        profile: AgentModelProfileIdentifier,
        gateway: AgentModelGatewayIdentifier,
        reason: AgentModelGatewayUnavailability
    )
    case gatewayNotFound(AgentModelGatewayIdentifier)
    case gatewayUnavailable(
        gateway: AgentModelGatewayIdentifier,
        reason: AgentModelGatewayUnavailability
    )
    case noRoute(AgentModelRoutePurpose)
    case profileRejected(
        profile: AgentModelProfileIdentifier,
        reason: String
    )

    public var errorDescription: String? {
        switch self {
        case .emptyIdentifier(let label):
            return "Agent model routing received an empty \(label) identifier."

        case .emptyModel(let profileIdentifier):
            return "Agent model profile '\(profileIdentifier.rawValue)' has no provider model value."

        case .profileNotFound(let profileIdentifier):
            return "No agent model profile exists for '\(profileIdentifier.rawValue)'."

        case .profileUnavailable(let profile, let gateway, let reason):
            let detail = reason.message ?? reason.kind.rawValue
            return "Agent model profile '\(profile.rawValue)' is unavailable because gateway '\(gateway.rawValue)' is unavailable: \(detail)"

        case .gatewayNotFound(let gatewayIdentifier):
            return "No agent model gateway exists for '\(gatewayIdentifier.rawValue)'."

        case .gatewayUnavailable(let gateway, let reason):
            let detail = reason.message ?? reason.kind.rawValue
            return "Agent model gateway '\(gateway.rawValue)' is unavailable: \(detail)"

        case .noRoute(let purpose):
            return "No agent model route could be selected for purpose '\(purpose.rawValue)'."

        case .profileRejected(let profile, let reason):
            return "Agent model profile '\(profile.rawValue)' cannot be used: \(reason)"
        }
    }
}
