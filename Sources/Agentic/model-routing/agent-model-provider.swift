public struct AgentModelProviderDescriptor: Sendable, Codable, Hashable, Identifiable {
    public var id: AgentModelProfileSourceIdentifier {
        source
    }

    public var source: AgentModelProfileSourceIdentifier
    public var adapterIdentifier: AgentModelAdapterIdentifier
    public var displayName: String
    public var metadata: [String: String]

    public init(
        source: AgentModelProfileSourceIdentifier,
        adapterIdentifier: AgentModelAdapterIdentifier,
        displayName: String,
        metadata: [String: String] = [:]
    ) {
        self.source = source
        self.adapterIdentifier = adapterIdentifier
        self.displayName = displayName
        self.metadata = metadata
    }
}

/// Rough future shape for provider packages.
///
/// This is deliberately minimal. It should not replace `AgentModelAdapter`,
/// `AgentModelProfileProvider`, or `AgentModelProfileDiscovery`.
///
/// Intended future package shape:
///
///     AgenticApple:
///         adapter + static profile provider
///
///     AgenticAWS:
///         adapter + static provider + discovery/snapshot provider
///
///     AgenticOpenAI / AgenticAnthropic:
///         adapter + curated static profiles first
///         optional discovery only if their APIs make it worthwhile
///
///     AgenticOllama:
///         adapter + local discovery from installed models
///
/// Providers are the installable composition boundary for model backends.
public protocol AgentModelProvider: Sendable {
    var descriptor: AgentModelProviderDescriptor { get }

    var adapter: AgentModelAdapterFactory? { get }

    var profileProvider: (any AgentModelProfileProvider)? { get }

    var discovery: (any AgentModelProfileDiscovery)? { get }
}

public extension AgentModelProvider {
    var adapter: AgentModelAdapterFactory? {
        nil
    }

    var profileProvider: (any AgentModelProfileProvider)? {
        nil
    }

    var discovery: (any AgentModelProfileDiscovery)? {
        nil
    }
}
