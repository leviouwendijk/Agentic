public struct AgentModelProviderDescriptor: Sendable, Codable, Hashable, Identifiable {
    public var id: AgentModelProfileSourceIdentifier {
        source
    }

    public var source: AgentModelProfileSourceIdentifier
    public var displayName: String
    public var metadata: [String: String]

    public init(
        source: AgentModelProfileSourceIdentifier,
        displayName: String,
        metadata: [String: String] = [:]
    ) {
        self.source = source
        self.displayName = displayName
        self.metadata = metadata
    }
}

/// Installable composition boundary for one model ecosystem.
///
/// A provider may contribute multiple independently configured gateways,
/// profile sources, and discovery sources. Provider identity does not select
/// an execution path; model invocation crosses an AgentModelGateway.
public protocol AgentModelProvider: Sendable {
    var descriptor: AgentModelProviderDescriptor { get }

    var gateways: [AgentModelGatewayFactory] { get }

    var profileProviders: [any AgentModelProfileProvider] { get }

    var discoveries: [any AgentModelProfileDiscovery] { get }
}

public extension AgentModelProvider {
    var gateways: [AgentModelGatewayFactory] {
        []
    }

    var profileProviders: [any AgentModelProfileProvider] {
        []
    }

    var discoveries: [any AgentModelProfileDiscovery] {
        []
    }
}
