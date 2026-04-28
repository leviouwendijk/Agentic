import Foundation

public enum AgentModelRoutingError: Error, Sendable, LocalizedError {
    case emptyIdentifier(String)
    case emptyModel(AgentModelProfileIdentifier)
    case profileNotFound(AgentModelProfileIdentifier)
    case adapterNotFound(AgentModelAdapterIdentifier)
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

        case .adapterNotFound(let adapterIdentifier):
            return "No agent model adapter exists for '\(adapterIdentifier.rawValue)'."

        case .noRoute(let purpose):
            return "No agent model route could be selected for purpose '\(purpose.rawValue)'."

        case .profileRejected(let profile, let reason):
            return "Agent model profile '\(profile.rawValue)' cannot be used: \(reason)"
        }
    }
}
