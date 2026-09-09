public struct AgentModelRequirements: Sendable, Codable, Hashable {
    public var capabilities: Set<AgentModelCapability>
    public var minimumInputCapacity: Int?
    public var minimumOutputCapacity: Int?

    public init(
        capabilities: Set<AgentModelCapability> = [
            .text,
        ],
        minimumInputCapacity: Int? = nil,
        minimumOutputCapacity: Int? = nil
    ) {
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
            )
        )
    }
}

public struct AgentModelPreferences: Sendable, Codable, Hashable {
    public var preferredProfileIdentifier: AgentModelProfileIdentifier?
    public var preferredModelID: AgentModelID?
    public var cost: AgentModelCostClass?
    public var latency: AgentModelLatencyClass?

    public init(
        preferredProfileIdentifier: AgentModelProfileIdentifier? = nil,
        preferredModelID: AgentModelID? = nil,
        cost: AgentModelCostClass? = nil,
        latency: AgentModelLatencyClass? = nil
    ) {
        self.preferredProfileIdentifier = preferredProfileIdentifier
        self.preferredModelID = preferredModelID
        self.cost = cost
        self.latency = latency
    }

    /// Apply a higher-precedence preference contribution.
    public func overriding(
        with higherPriority: Self
    ) -> Self {
        .init(
            preferredProfileIdentifier:
                higherPriority.preferredProfileIdentifier
                    ?? preferredProfileIdentifier,
            preferredModelID:
                higherPriority.preferredModelID
                    ?? preferredModelID,
            cost:
                higherPriority.cost
                    ?? cost,
            latency:
                higherPriority.latency
                    ?? latency
        )
    }
}

public struct AgentModelConstraints: Sendable, Codable, Hashable {
    public var allowedProviderIDs: Set<AgentModelProviderID>?
    public var allowedAdapterIdentifiers: Set<AgentModelAdapterIdentifier>?
    public var allowedModelIDs: Set<AgentModelID>?
    public var allowedProfileIdentifiers: Set<AgentModelProfileIdentifier>?
    public var allowsExternal: Bool
    public var minimumPrivacy: AgentModelPrivacyClass?
    public var maximumEstimatedUsd: Double?

    public init(
        allowedProviderIDs: Set<AgentModelProviderID>? = nil,
        allowedAdapterIdentifiers: Set<AgentModelAdapterIdentifier>? = nil,
        allowedModelIDs: Set<AgentModelID>? = nil,
        allowedProfileIdentifiers: Set<AgentModelProfileIdentifier>? = nil,
        allowsExternal: Bool = true,
        minimumPrivacy: AgentModelPrivacyClass? = nil,
        maximumEstimatedUsd: Double? = nil
    ) {
        self.allowedProviderIDs = allowedProviderIDs
        self.allowedAdapterIdentifiers = allowedAdapterIdentifiers
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
            allowedAdapterIdentifiers: intersection(
                allowedAdapterIdentifiers,
                other.allowedAdapterIdentifiers
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
    public var requirements: AgentModelRequirements
    public var preferences: AgentModelPreferences
    public var constraints: AgentModelConstraints
    public var metadata: [String: String]

    public init(
        purpose: AgentModelRoutePurpose,
        requirements: AgentModelRequirements = .init(),
        preferences: AgentModelPreferences = .init(),
        constraints: AgentModelConstraints = .init(),
        metadata: [String: String] = [:]
    ) {
        self.purpose = purpose
        self.requirements = requirements
        self.preferences = preferences
        self.constraints = constraints
        self.metadata = metadata
    }
}

public extension AgentModelSelection {
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
