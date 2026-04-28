public extension AgentRequest {
    func routed(
        through result: AgentModelRouteResult
    ) -> AgentRequest {
        var request = self
        let profile = result.route.profile

        request.model = profile.model
        request.metadata = request.metadata.merging(
            result.route.agentMetadata(
                reasons: result.reasons,
                warnings: result.warnings
            )
        ) { _, new in
            new
        }

        return request
    }
}

public extension AgentResponse {
    func routed(
        through result: AgentModelRouteResult
    ) -> AgentResponse {
        .init(
            message: message,
            stopReason: stopReason,
            usage: usage,
            metadata: metadata.merging(
                result.route.agentMetadata(
                    reasons: result.reasons,
                    warnings: result.warnings
                )
            ) { _, new in
                new
            }
        )
    }
}

public extension AgentStreamEvent {
    func routed(
        through result: AgentModelRouteResult
    ) -> AgentStreamEvent {
        switch self {
        case .messagedelta,
             .toolcall,
             .toolresult:
            return self

        case .completed(let response):
            return .completed(
                response.routed(
                    through: result
                )
            )
        }
    }
}

public extension AgentModelRoute {
    func agentMetadata(
        reasons: [String] = [],
        warnings: [String] = []
    ) -> [String: String] {
        var metadata = metadata

        metadata["model_route_purpose"] = purpose.rawValue
        metadata["model_profile"] = profile.identifier.rawValue
        metadata["model_adapter"] = profile.adapterIdentifier.rawValue
        metadata["model"] = profile.model
        metadata["model_cost"] = profile.cost.rawValue
        metadata["model_latency"] = profile.latency.rawValue
        metadata["model_privacy"] = profile.privacy.rawValue

        if !reasons.isEmpty {
            metadata["model_route_reasons"] = reasons.joined(
                separator: ","
            )
        }

        if !warnings.isEmpty {
            metadata["model_route_warnings"] = warnings.joined(
                separator: "\n"
            )
        }

        return metadata
    }
}
