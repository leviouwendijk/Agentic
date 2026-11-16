public struct AgentModelRequirements: Sendable, Codable, Hashable {
    public var capabilities: Set<AgentModelCapability>
    public var minimumInputCapacity: Int?
    public var minimumOutputCapacity: Int?
    /// The least capable tier this work accepts, e.g. a planner that must
    /// be `strong` in one agent and may be `standard` in another.
    public var minimumTier: AgentModelTier?

    public init(
        capabilities: Set<AgentModelCapability> = [
            .text,
        ],
        minimumInputCapacity: Int? = nil,
        minimumOutputCapacity: Int? = nil,
        minimumTier: AgentModelTier? = nil
    ) {
        self.minimumTier = minimumTier
        self.capabilities = capabilities
        self.minimumInputCapacity = minimumInputCapacity.map {
            max(0, $0)
        }
        self.minimumOutputCapacity = minimumOutputCapacity.map {
            max(0, $0)
        }
    }

    public func merging(
        _ other: Self
    ) -> Self {
        .init(
            capabilities: capabilities.union(
                other.capabilities
            ),
            minimumInputCapacity: maximum(
                minimumInputCapacity,
                other.minimumInputCapacity
            ),
            minimumOutputCapacity: maximum(
                minimumOutputCapacity,
                other.minimumOutputCapacity
            ),
            minimumTier: [minimumTier, other.minimumTier].compactMap { $0 }.max()
        )
    }
}

public struct AgentModelPreferences: Sendable, Codable, Hashable {
    /// Explicit targets are binding unless fallback is deliberately enabled.
    public var allowsFallback: Bool
    public var preferredProfileIdentifier: AgentModelProfileIdentifier?
    public var preferredModelID: AgentModelID?
    public var gateway: AgentModelGatewayIdentifier?
    /// Ordered fallback gateways tried after `gateway`. Together they form
    /// one target: the first gateway in `gatewayChain` able to serve the
    /// selection wins.
    public var gateways: [AgentModelGatewayIdentifier]
    public var cost: AgentModelCostClass?
    public var latency: AgentModelLatencyClass?

    public init(
        preferredProfileIdentifier: AgentModelProfileIdentifier? = nil,
        preferredModelID: AgentModelID? = nil,
        gateway: AgentModelGatewayIdentifier? = nil,
        gateways: [AgentModelGatewayIdentifier] = [],
        allowsFallback: Bool = false,
        cost: AgentModelCostClass? = nil,
        latency: AgentModelLatencyClass? = nil
    ) {
        self.preferredProfileIdentifier = preferredProfileIdentifier
        self.preferredModelID = preferredModelID
        self.gateway = gateway
        self.gateways = gateways
        self.allowsFallback = allowsFallback
        self.cost = cost
        self.latency = latency
    }

    /// `gateway` followed by `gateways`, without repeats, in preference order.
    public var gatewayChain: [AgentModelGatewayIdentifier] {
        var seen = Set<AgentModelGatewayIdentifier>()
        return ([gateway].compactMap { $0 } + gateways).filter {
            seen.insert($0).inserted
        }
    }

    /// A model target (profile, model, or gateway chain) is one coherent choice.
    /// A higher-priority target clears lower-priority target fields.
    public func overriding(
        with higherPriority: Self
    ) -> Self {
        let overridesTarget =
            higherPriority.preferredProfileIdentifier != nil
            || higherPriority.preferredModelID != nil
            || !higherPriority.gatewayChain.isEmpty

        return .init(
            preferredProfileIdentifier: overridesTarget
                ? higherPriority.preferredProfileIdentifier
                : preferredProfileIdentifier,
            preferredModelID: overridesTarget
                ? higherPriority.preferredModelID
                : preferredModelID,
            gateway: overridesTarget
                ? higherPriority.gateway
                : gateway,
            gateways: overridesTarget
                ? higherPriority.gateways
                : gateways,
            allowsFallback: overridesTarget ? higherPriority.allowsFallback : allowsFallback,
            cost: higherPriority.cost ?? cost,
            latency: higherPriority.latency ?? latency
        )
    }

    private enum CodingKeys: String, CodingKey {
        case allowsFallback
        case preferredProfileIdentifier
        case preferredModelID
        case gateway
        case gateways
        case cost
        case latency
    }

    // Preferences encoded before gateway chains existed stay decodable.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            preferredProfileIdentifier: try values.decodeIfPresent(AgentModelProfileIdentifier.self, forKey: .preferredProfileIdentifier),
            preferredModelID: try values.decodeIfPresent(AgentModelID.self, forKey: .preferredModelID),
            gateway: try values.decodeIfPresent(AgentModelGatewayIdentifier.self, forKey: .gateway),
            gateways: try values.decodeIfPresent([AgentModelGatewayIdentifier].self, forKey: .gateways) ?? [],
            allowsFallback: try values.decodeIfPresent(Bool.self, forKey: .allowsFallback) ?? false,
            cost: try values.decodeIfPresent(AgentModelCostClass.self, forKey: .cost),
            latency: try values.decodeIfPresent(AgentModelLatencyClass.self, forKey: .latency)
        )
    }
}

public struct AgentModelConstraints: Sendable, Codable, Hashable {
    public var allowedProviderIDs: Set<AgentModelProviderID>?
    public var allowedGatewayIdentifiers: Set<AgentModelGatewayIdentifier>?
    public var allowedModelIDs: Set<AgentModelID>?
    public var allowedProfileIdentifiers: Set<AgentModelProfileIdentifier>?
    public var allowsExternal: Bool
    public var minimumPrivacy: AgentModelPrivacyClass?
    public var maximumEstimatedUsd: Double?

    public init(
        allowedProviderIDs: Set<AgentModelProviderID>? = nil,
        allowedGatewayIdentifiers: Set<AgentModelGatewayIdentifier>? = nil,
        allowedModelIDs: Set<AgentModelID>? = nil,
        allowedProfileIdentifiers: Set<AgentModelProfileIdentifier>? = nil,
        allowsExternal: Bool = true,
        minimumPrivacy: AgentModelPrivacyClass? = nil,
        maximumEstimatedUsd: Double? = nil
    ) {
        self.allowedProviderIDs = allowedProviderIDs
        self.allowedGatewayIdentifiers = allowedGatewayIdentifiers
        self.allowedModelIDs = allowedModelIDs
        self.allowedProfileIdentifiers = allowedProfileIdentifiers
        self.allowsExternal = allowsExternal
        self.minimumPrivacy = minimumPrivacy
        self.maximumEstimatedUsd = maximumEstimatedUsd.map {
            max(0, $0)
        }
    }

    public func tightened(
        by other: Self
    ) -> Self {
        .init(
            allowedProviderIDs: intersection(
                allowedProviderIDs,
                other.allowedProviderIDs
            ),
            allowedGatewayIdentifiers: intersection(
                allowedGatewayIdentifiers,
                other.allowedGatewayIdentifiers
            ),
            allowedModelIDs: intersection(
                allowedModelIDs,
                other.allowedModelIDs
            ),
            allowedProfileIdentifiers: intersection(
                allowedProfileIdentifiers,
                other.allowedProfileIdentifiers
            ),
            allowsExternal: allowsExternal && other.allowsExternal,
            minimumPrivacy: stricter(
                minimumPrivacy,
                other.minimumPrivacy
            ),
            maximumEstimatedUsd: minimum(
                maximumEstimatedUsd,
                other.maximumEstimatedUsd
            )
        )
    }
}

public struct AgentModelSelection: Sendable, Codable, Hashable {
    public var purpose: AgentModelRoutePurpose
    public var operation: AgentModelOperation
    public var requirements: AgentModelRequirements
    public var preferences: AgentModelPreferences
    public var constraints: AgentModelConstraints
    public var metadata: [String: String]

    public init(
        purpose: AgentModelRoutePurpose,
        operation: AgentModelOperation = .generation,
        requirements: AgentModelRequirements = .init(),
        preferences: AgentModelPreferences = .init(),
        constraints: AgentModelConstraints = .init(),
        metadata: [String: String] = [:]
    ) {
        self.purpose = purpose
        self.operation = operation
        self.requirements = requirements
        self.preferences = preferences
        self.constraints = constraints
        self.metadata = metadata
    }
}

public extension AgentModelSelection {
    static func exactModel(
        _ modelID: AgentModelID,
        purpose: AgentModelRoutePurpose = .executor,
        through gateway: AgentModelGatewayIdentifier? = nil
    ) -> Self {
        .init(
            purpose: purpose,
            preferences: .init(
                preferredModelID: modelID,
                gateway: gateway
            ),
            constraints: .init(
                allowedGatewayIdentifiers: gateway.map {
                    Set([$0])
                },
                allowedModelIDs: [
                    modelID,
                ]
            )
        )
    }

    static func exactProfile(
        _ profileIdentifier: AgentModelProfileIdentifier,
        purpose: AgentModelRoutePurpose = .executor
    ) -> Self {
        .init(
            purpose: purpose,
            preferences: .init(
                preferredProfileIdentifier: profileIdentifier
            ),
            constraints: .init(
                allowedProfileIdentifiers: [
                    profileIdentifier,
                ]
            )
        )
    }

    static let executor = Self(
        purpose: .executor
    )

    static let planner = Self(
        purpose: .planner,
        requirements: .init(
            capabilities: [
                .text,
                .reasoning,
            ]
        ),
        metadata: [
            "route_role": "planner",
        ]
    )

    static let researcher = Self(
        purpose: .researcher,
        requirements: .init(
            capabilities: [
                .text,
                .reasoning,
                .structured_output,
            ]
        ),
        metadata: [
            "route_role": "researcher",
        ]
    )

    static let advisor = Self(
        purpose: .advisor,
        requirements: .init(
            capabilities: [
                .text,
                .reasoning,
            ]
        )
    )

    static let reviewer = Self(
        purpose: .reviewer,
        requirements: .init(
            capabilities: [
                .text,
                .reasoning,
            ]
        )
    )

    static let summarizer = Self(
        purpose: .summarizer
    )

    static let classifier = Self(
        purpose: .classifier
    )

    static let extractor = Self(
        purpose: .extractor,
        requirements: .init(
            capabilities: [
                .text,
                .structured_output,
            ]
        )
    )

    static let coder = Self(
        purpose: .coder,
        requirements: .init(
            capabilities: [
                .text,
                .reasoning,
            ]
        )
    )

    static let local_private = Self(
        purpose: .local_private,
        constraints: .init(
            allowsExternal: false,
            minimumPrivacy: .local_private
        )
    )
}

private func maximum(
    _ lhs: Int?,
    _ rhs: Int?
) -> Int? {
    switch (lhs, rhs) {
    case (.none, .none):
        nil

    case (.some(let value), .none),
         (.none, .some(let value)):
        value

    case (.some(let lhs), .some(let rhs)):
        max(lhs, rhs)
    }
}

private func minimum(
    _ lhs: Double?,
    _ rhs: Double?
) -> Double? {
    switch (lhs, rhs) {
    case (.none, .none):
        nil

    case (.some(let value), .none),
         (.none, .some(let value)):
        value

    case (.some(let lhs), .some(let rhs)):
        min(lhs, rhs)
    }
}

private func intersection<Value: Hashable>(
    _ lhs: Set<Value>?,
    _ rhs: Set<Value>?
) -> Set<Value>? {
    switch (lhs, rhs) {
    case (.none, .none):
        nil

    case (.some(let value), .none),
         (.none, .some(let value)):
        value

    case (.some(let lhs), .some(let rhs)):
        lhs.intersection(rhs)
    }
}

private func stricter(
    _ lhs: AgentModelPrivacyClass?,
    _ rhs: AgentModelPrivacyClass?
) -> AgentModelPrivacyClass? {
    switch (lhs, rhs) {
    case (.none, .none):
        nil

    case (.some(let value), .none),
         (.none, .some(let value)):
        value

    case (.some(let lhs), .some(let rhs)):
        lhs.rank >= rhs.rank
            ? lhs
            : rhs
    }
}
