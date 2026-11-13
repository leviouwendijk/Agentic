public extension AgentModelProfile {
    typealias ID = AgentModelProfileIdentifier

    struct Gateway:
        Sendable,
        Codable,
        Hashable
    {
        public typealias ID = AgentModelGatewayIdentifier

        public var id: ID
        public var model: String

        public init(
            id: ID,
            model: String
        ) {
            self.id = id
            self.model = model
        }
    }

    var gateway: Gateway {
        get {
            .init(
                id: gatewayIdentifier,
                model: model
            )
        }
        set {
            gatewayIdentifier = newValue.id
            model = newValue.model
        }
    }

    init(
        identifier: ID,
        gateway: Gateway,
        modelID: AgentModel.ID? = nil,
        title: String? = nil,
        purposes: Set<AgentModelRoutePurpose> = [.executor],
        capabilities: Set<AgentModelCapability> = [.text],
        cost: AgentModelCostClass = .balanced,
        latency: AgentModelLatencyClass = .medium,
        privacy: AgentModelPrivacyClass = .private_cloud,
        limits: AgentModelLimits = .unknown,
        metadata: [String: String] = [:]
    ) {
        self.init(
            identifier: identifier,
            gatewayIdentifier: gateway.id,
            model: gateway.model,
            modelID: modelID,
            title: title,
            purposes: purposes,
            capabilities: capabilities,
            cost: cost,
            latency: latency,
            privacy: privacy,
            limits: limits,
            metadata: metadata
        )
    }
}

public extension AgentModelPreferences {
    var profile: AgentModelProfile.ID? {
        get {
            preferredProfileIdentifier
        }
        set {
            preferredProfileIdentifier = newValue
        }
    }

    var model: AgentModel.ID? {
        get {
            preferredModelID
        }
        set {
            preferredModelID = newValue
        }
    }

    init(
        profile: AgentModelProfile.ID,
        model: AgentModel.ID? = nil,
        gateway: AgentModelGatewayIdentifier? = nil,
        cost: AgentModelCostClass? = nil,
        latency: AgentModelLatencyClass? = nil
    ) {
        self.init(
            preferredProfileIdentifier: profile,
            preferredModelID: model,
            gateway: gateway,
            cost: cost,
            latency: latency
        )
    }

    init(
        model: AgentModel.ID,
        gateway: AgentModelGatewayIdentifier? = nil,
        cost: AgentModelCostClass? = nil,
        latency: AgentModelLatencyClass? = nil
    ) {
        self.init(
            preferredModelID: model,
            gateway: gateway,
            cost: cost,
            latency: latency
        )
    }

    init(
        gateway: AgentModelGatewayIdentifier,
        cost: AgentModelCostClass? = nil,
        latency: AgentModelLatencyClass? = nil
    ) {
        self.init(
            preferredProfileIdentifier: nil,
            preferredModelID: nil,
            gateway: gateway,
            cost: cost,
            latency: latency
        )
    }
}

public extension AgentModelConstraints {
    var gateways: Set<AgentModelGatewayIdentifier>? {
        get {
            allowedGatewayIdentifiers
        }
        set {
            allowedGatewayIdentifiers = newValue
        }
    }

    var models: Set<AgentModel.ID>? {
        get {
            allowedModelIDs
        }
        set {
            allowedModelIDs = newValue
        }
    }

    var profiles: Set<AgentModelProfile.ID>? {
        get {
            allowedProfileIdentifiers
        }
        set {
            allowedProfileIdentifiers = newValue
        }
    }
}
