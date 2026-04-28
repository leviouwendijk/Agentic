public struct AgentModelProfile: Sendable, Codable, Hashable, Identifiable {
    public let identifier: AgentModelProfileIdentifier
    public var adapterIdentifier: AgentModelAdapterIdentifier
    public var model: String
    public var modelID: AgentModelID?
    public var title: String?
    public var purposes: Set<AgentModelRoutePurpose>
    public var capabilities: Set<AgentModelCapability>
    public var cost: AgentModelCostClass
    public var latency: AgentModelLatencyClass
    public var privacy: AgentModelPrivacyClass
    public var limits: AgentModelLimits
    public var metadata: [String: String]

    public init(
        identifier: AgentModelProfileIdentifier,
        adapterIdentifier: AgentModelAdapterIdentifier,
        model: String,
        modelID: AgentModelID? = nil,
        title: String? = nil,
        purposes: Set<AgentModelRoutePurpose> = [.executor],
        capabilities: Set<AgentModelCapability> = [.text],
        cost: AgentModelCostClass = .balanced,
        latency: AgentModelLatencyClass = .medium,
        privacy: AgentModelPrivacyClass = .private_cloud,
        limits: AgentModelLimits = .unknown,
        metadata: [String: String] = [:]
    ) {
        self.identifier = identifier
        self.adapterIdentifier = adapterIdentifier
        self.model = model
        self.modelID = modelID
        self.title = title
        self.purposes = purposes
        self.capabilities = capabilities
        self.cost = cost
        self.latency = latency
        self.privacy = privacy
        self.limits = limits
        self.metadata = metadata
    }

    public var id: AgentModelProfileIdentifier {
        identifier
    }

    public var providerModelIdentifier: String {
        model
    }

    public func supports(
        _ policy: AgentModelUsePolicy
    ) -> Bool {
        guard purposes.contains(
            policy.purpose
        ) else {
            return false
        }

        guard capabilities.isSuperset(
            of: policy.capabilities
        ) else {
            return false
        }

        if let preferredModelID = policy.preferredModelID,
           modelID != preferredModelID {
            return false
        }

        if !policy.external,
           privacy.isExternal {
            return false
        }

        if privacy.rank < policy.privacy.rank {
            return false
        }

        if let maxInputTokens = policy.maxInputTokens,
           let inputTokens = limits.inputTokens,
           inputTokens < maxInputTokens {
            return false
        }

        if let maxOutputTokens = policy.maxOutputTokens,
           let outputTokens = limits.outputTokens,
           outputTokens < maxOutputTokens {
            return false
        }

        return true
    }
}
