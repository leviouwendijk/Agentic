public struct AgentModelProfile: Sendable, Codable, Hashable, Identifiable {
    public let identifier: AgentModelProfileIdentifier
    public var gatewayIdentifier: AgentModelGatewayIdentifier
    public var model: String
    public var modelID: AgentModelID?
    public var title: String?
    public var kind: AgentModelKind
    public var operations: Set<AgentModelOperation>
    public var purposes: Set<AgentModelRoutePurpose>
    public var capabilities: Set<AgentModelCapability>
    /// Nil when nobody has judged the model; a minimum-tier requirement
    /// then refuses it rather than assume.
    public var tier: AgentModelTier?
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
        kind: AgentModelKind = .generative,
        operations: Set<AgentModelOperation>? = nil,
        purposes: Set<AgentModelRoutePurpose> = AgentModelRoutePurpose.general,
        capabilities: Set<AgentModelCapability> = [.text],
        tier: AgentModelTier? = nil,
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
        self.kind = kind
        self.operations = operations ?? (kind == .decision ? [.decision] : [.generation])
        self.purposes = purposes
        self.capabilities = capabilities
        self.tier = tier
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
        rejection(for: selection) == nil
    }

    /// Why this profile cannot serve `selection`, in words an operator can
    /// act on; nil when it can.
    public func rejection(
        for selection: AgentModelSelection
    ) -> String? {
        guard operations.contains(selection.operation) else {
            return "does not perform \(selection.operation.rawValue)"
        }

        guard purposes.contains(selection.purpose) else {
            return "does not serve the \(selection.purpose.rawValue) role"
        }

        let requirements = selection.requirements
        let constraints = selection.constraints

        let missing = requirements.capabilities.subtracting(capabilities)
        guard missing.isEmpty else {
            return "lacks " + missing.map(\.rawValue).sorted().joined(separator: ", ")
        }

        if let minimumTier = requirements.minimumTier {
            guard let tier else {
                return "has no declared tier; the role needs at least \(minimumTier.rawValue)"
            }
            guard tier >= minimumTier else {
                return "is \(tier.rawValue); the role needs at least \(minimumTier.rawValue)"
            }
        }

        if let allowedProfileIdentifiers = constraints.allowedProfileIdentifiers,
           !allowedProfileIdentifiers.contains(identifier) {
            return "is outside the allowed profiles"
        }

        if let allowedGatewayIdentifiers = constraints.allowedGatewayIdentifiers,
           !allowedGatewayIdentifiers.contains(gatewayIdentifier) {
            return "is served by a gateway outside the allowed ones"
        }

        if let allowedModelIDs = constraints.allowedModelIDs {
            guard let modelID,
                  allowedModelIDs.contains(modelID)
            else {
                return "is outside the allowed models"
            }
        }

        if let allowedProviderIDs = constraints.allowedProviderIDs {
            guard let modelID,
                  allowedProviderIDs.contains(modelID.provider)
            else {
                return "is from a provider outside the allowed ones"
            }
        }

        if !constraints.allowsExternal,
           privacy.isExternal {
            return "is an external service, which is not allowed here"
        }

        if let minimumPrivacy = constraints.minimumPrivacy,
           privacy.rank < minimumPrivacy.rank {
            return "is less private than required (\(minimumPrivacy.rawValue))"
        }

        if let minimumInputCapacity = requirements.minimumInputCapacity {
            guard let inputTokens = limits.inputTokens,
                  inputTokens >= minimumInputCapacity
            else {
                return "reads fewer than \(minimumInputCapacity) input tokens, or its limit is unknown"
            }
        }

        if let minimumOutputCapacity = requirements.minimumOutputCapacity {
            guard let outputTokens = limits.outputTokens,
                  outputTokens >= minimumOutputCapacity
            else {
                return "writes fewer than \(minimumOutputCapacity) output tokens, or its limit is unknown"
            }
        }

        return nil
    }
}
