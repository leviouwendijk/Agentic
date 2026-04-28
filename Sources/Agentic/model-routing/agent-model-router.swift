public protocol AgentModelRouter: Sendable {
    func route(
        _ request: AgentModelRouteRequest,
        catalog: AgentModelProfileCatalog
    ) throws -> AgentModelRouteResult
}

public struct StaticAgentModelRouter: AgentModelRouter {
    public var defaults: [AgentModelRoutePurpose: AgentModelProfileIdentifier]
    public var fallback: [AgentModelRoutePurpose]
    public var defaultProfileIdentifier: AgentModelProfileIdentifier?

    public init(
        defaults: [AgentModelRoutePurpose: AgentModelProfileIdentifier] = [:],
        fallback: [AgentModelRoutePurpose] = [
            .executor,
            .summarizer,
            .classifier
        ],
        defaultProfileIdentifier: AgentModelProfileIdentifier? = nil
    ) {
        self.defaults = defaults
        self.fallback = fallback
        self.defaultProfileIdentifier = defaultProfileIdentifier
    }

    public func route(
        _ request: AgentModelRouteRequest,
        catalog: AgentModelProfileCatalog
    ) throws -> AgentModelRouteResult {
        if let preferredProfileIdentifier = request.policy.preferredProfileIdentifier {
            return try route(
                preferredProfileIdentifier,
                request: request,
                catalog: catalog,
                reason: "preferred_profile"
            )
        }

        if let defaultIdentifier = defaults[request.policy.purpose] {
            return try route(
                defaultIdentifier,
                request: request,
                catalog: catalog,
                reason: "purpose_default"
            )
        }

        if let matched = catalog.profiles(
            for: request.policy.purpose
        ).first(
            where: {
                $0.supports(
                    request.policy
                )
            }
        ) {
            return .init(
                route: .init(
                    purpose: request.policy.purpose,
                    profile: matched,
                    metadata: routeMetadata(
                        request
                    )
                ),
                reasons: [
                    "purpose_match"
                ]
            )
        }

        for purpose in fallback {
            var fallbackPolicy = request.policy
            fallbackPolicy.purpose = purpose

            if let matched = catalog.profiles(
                for: purpose
            ).first(
                where: {
                    $0.supports(
                        fallbackPolicy
                    )
                }
            ) {
                return .init(
                    route: .init(
                        purpose: request.policy.purpose,
                        profile: matched,
                        metadata: routeMetadata(
                            request
                        )
                    ),
                    reasons: [
                        "fallback",
                        purpose.rawValue
                    ],
                    warnings: [
                        "No direct profile matched \(request.policy.purpose.rawValue); using fallback purpose \(purpose.rawValue)."
                    ]
                )
            }
        }

        if let defaultProfileIdentifier {
            return try route(
                defaultProfileIdentifier,
                request: request,
                catalog: catalog,
                reason: "global_default"
            )
        }

        throw AgentModelRoutingError.noRoute(
            request.policy.purpose
        )
    }
}

private extension StaticAgentModelRouter {
    func route(
        _ profileIdentifier: AgentModelProfileIdentifier,
        request: AgentModelRouteRequest,
        catalog: AgentModelProfileCatalog,
        reason: String
    ) throws -> AgentModelRouteResult {
        let profile = try catalog.profile(
            profileIdentifier
        )

        guard profile.supports(
            request.policy
        ) else {
            throw AgentModelRoutingError.profileRejected(
                profile: profileIdentifier,
                reason: "profile does not satisfy purpose, capability, privacy, or token policy"
            )
        }

        return .init(
            route: .init(
                purpose: request.policy.purpose,
                profile: profile,
                metadata: routeMetadata(
                    request
                )
            ),
            reasons: [
                reason
            ]
        )
    }

    func routeMetadata(
        _ request: AgentModelRouteRequest
    ) -> [String: String] {
        var metadata = request.metadata

        for (key, value) in request.policy.metadata {
            metadata[key] = value
        }

        return metadata
    }
}
