public struct AgentModelProfile: Sendable, Codable, Hashable, Identifiable {
    public let identifier: AgentModelProfileIdentifier
    public var gatewayIdentifier: AgentModelGatewayIdentifier
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
        gatewayIdentifier: AgentModelGatewayIdentifier,
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
        self.gatewayIdentifier = gatewayIdentifier
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

    /// Evaluate the profile facts that are available before an invocation is
    /// priced. A maximum estimated cost is enforced later by the model control
    /// plane once an invocation-specific estimate exists.
    public func supports(
        _ selection: AgentModelSelection
    ) -> Bool {
        guard purposes.contains(
            selection.purpose
        ) else {
            return false
        }

        let requirements = selection.requirements
        let constraints = selection.constraints

        guard capabilities.isSuperset(
            of: requirements.capabilities
        ) else {
            return false
        }

        if let allowedProfileIdentifiers = constraints.allowedProfileIdentifiers,
           !allowedProfileIdentifiers.contains(identifier) {
            return false
        }

        if let allowedGatewayIdentifiers = constraints.allowedGatewayIdentifiers,
           !allowedGatewayIdentifiers.contains(gatewayIdentifier) {
            return false
        }

        if let allowedModelIDs = constraints.allowedModelIDs {
            guard let modelID,
                  allowedModelIDs.contains(modelID)
            else {
                return false
            }
        }

        if let allowedProviderIDs = constraints.allowedProviderIDs {
            guard let modelID,
                  allowedProviderIDs.contains(modelID.provider)
            else {
                return false
            }
        }

        if !constraints.allowsExternal,
           privacy.isExternal {
            return false
        }

        if let minimumPrivacy = constraints.minimumPrivacy,
           privacy.rank < minimumPrivacy.rank {
            return false
        }

        if let minimumInputCapacity = requirements.minimumInputCapacity {
            guard let inputTokens = limits.inputTokens,
                  inputTokens >= minimumInputCapacity
            else {
                return false
            }
        }

        if let minimumOutputCapacity = requirements.minimumOutputCapacity {
            guard let outputTokens = limits.outputTokens,
                  outputTokens >= minimumOutputCapacity
            else {
                return false
            }
        }

        return true
    }
}
