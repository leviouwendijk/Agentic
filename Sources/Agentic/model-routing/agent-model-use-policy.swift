public struct AgentModelUsePolicy: Sendable, Codable, Hashable {
    public var purpose: AgentModelRoutePurpose
    public var capabilities: Set<AgentModelCapability>
    public var privacy: AgentModelPrivacyClass
    public var external: Bool
    public var maxInputTokens: Int?
    public var maxOutputTokens: Int?
    public var maxEstimatedUsd: Double?
    public var preferredProfileIdentifier: AgentModelProfileIdentifier?
    public var metadata: [String: String]

    public init(
        purpose: AgentModelRoutePurpose,
        capabilities: Set<AgentModelCapability> = [.text],
        privacy: AgentModelPrivacyClass = .external_cloud,
        external: Bool = true,
        maxInputTokens: Int? = nil,
        maxOutputTokens: Int? = nil,
        maxEstimatedUsd: Double? = nil,
        preferredProfileIdentifier: AgentModelProfileIdentifier? = nil,
        metadata: [String: String] = [:]
    ) {
        self.purpose = purpose
        self.capabilities = capabilities
        self.privacy = privacy
        self.external = external
        self.maxInputTokens = maxInputTokens.map {
            max(0, $0)
        }
        self.maxOutputTokens = maxOutputTokens.map {
            max(0, $0)
        }
        self.maxEstimatedUsd = maxEstimatedUsd.map {
            max(0, $0)
        }
        self.preferredProfileIdentifier = preferredProfileIdentifier
        self.metadata = metadata
    }
}

public extension AgentModelUsePolicy {
    static let executor = Self(
        purpose: .executor
    )

    static let planner = Self(
        purpose: .planner,
        capabilities: [
            .text,
            .reasoning
        ],
        metadata: [
            "route_role": "planner"
        ]
    )

    static let researcher = Self(
        purpose: .researcher,
        capabilities: [
            .text,
            .reasoning,
            .structured_output
        ],
        metadata: [
            "route_role": "researcher"
        ]
    )

    static let advisor = Self(
        purpose: .advisor,
        capabilities: [
            .text,
            .reasoning
        ]
    )

    static let reviewer = Self(
        purpose: .reviewer,
        capabilities: [
            .text,
            .reasoning
        ]
    )

    static let summarizer = Self(
        purpose: .summarizer
    )

    static let classifier = Self(
        purpose: .classifier
    )

    static let extractor = Self(
        purpose: .extractor,
        capabilities: [
            .text,
            .structured_output
        ]
    )

    static let coder = Self(
        purpose: .coder,
        capabilities: [
            .text,
            .reasoning
        ]
    )

    static let local_private = Self(
        purpose: .local_private,
        privacy: .local_private,
        external: false
    )
}
