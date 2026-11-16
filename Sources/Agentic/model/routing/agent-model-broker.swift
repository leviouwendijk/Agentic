import Foundation
import Schema


public struct ModelBroker: Sendable, AgentModelInvoking {
    public let profiles: ProfileCatalog
    public let routableProfiles: ProfileCatalog
    public let gateways: GatewayCatalog
    public let router: any ModelRouter
    public let selectionResolver: ModelSelectionResolver
    public let ledger: (any AgentModelRouteLedger)?

    public init(
        profiles: ProfileCatalog,
        gateways: GatewayCatalog,
        router: any ModelRouter = StaticModelRouter(),
        selectionResolver: ModelSelectionResolver = .init(),
        ledger: (any AgentModelRouteLedger)? = nil
    ) {
        self.profiles = profiles
        self.routableProfiles = profiles.routable(
            using: gateways
        )
        self.gateways = gateways
        self.router = router
        self.selectionResolver = selectionResolver
        self.ledger = ledger
    }

    /// Count only when explicitly requested. Uses the same routing and output
    /// adaptation as generation; does not invoke a model or record generation.
    public func countInputTokens(
        _ invocation: AgentModelInvocation
    ) async throws -> AgentModelInvocation.InputCount {
        let prepared = try prepare(invocation)
        let gateway = try gateways.gateway(
            for: prepared.routeResult.route.profile.gateway.id
        )
        let count = try await gateway.response.countInputTokens(
            request: prepared.request,
            route: prepared.routeResult.route,
            context: invocation.context
        )
        return try .init(
            request: prepared.request,
            route: prepared.routeResult,
            inputTokens: count
        )
    }

    public func buffered(
        _ invocation: AgentModelInvocation
    ) async throws -> AgentModelInvocation.Result {
        let prepared = try prepare(
            invocation
        )
        let gateway = try gateways.gateway(
            for: prepared.routeResult.route.profile.gateway.id
        )
        let response = try await gateway.respond(
            request: prepared.request,
            route: prepared.routeResult.route,
            context: invocation.context
        )
        let routeRecord = try await record(
            prepared.routeResult,
            requestMetadata: prepared.requestMetadata,
            response: response
        )

        return .init(
            response: response,
            route: routeRecord
        )
    }

    public func stream(
        _ invocation: AgentModelInvocation
    ) -> AsyncThrowingStream<AgentModelInvocation.Event, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let prepared = try prepare(
                        invocation
                    )
                    let gateway = try gateways.gateway(
                        for: prepared.routeResult.route.profile.gateway.id
                    )

                    continuation.yield(
                        .routed(
                            prepared.routeResult
                        )
                    )

                    for try await event in gateway.respond(
                        request: prepared.request,
                        route: prepared.routeResult.route,
                        delivery: .stream,
                        context: invocation.context
                    ) {
                        switch event {
                        case .completed(let response):
                            let routeRecord = try await record(
                                prepared.routeResult,
                                requestMetadata: prepared.requestMetadata,
                                response: response
                            )

                            continuation.yield(
                                .completed(
                                    .init(
                                        response: response,
                                        route: routeRecord
                                    )
                                )
                            )

                        default:
                            continuation.yield(
                                .model(event)
                            )
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(
                        throwing: error
                    )
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    public func route(
        selection: AgentModelSelection,
        metadata: [String: String] = [:]
    ) throws -> AgentModelRouteResult {
        let resolution = try selectionResolver.resolve(
            selection
        )
        let routed = try route(
            .init(
                selection: resolution.selection,
                metadata: metadata
            )
        )

        return .init(
            route: routed.route,
            diagnostics:
                resolution.diagnostics
                + routed.diagnostics
        )
    }
}

private extension ModelBroker {
    struct PreparedInvocation {
        var routeResult: AgentModelRouteResult
        var requestMetadata: [String: String]
        /// What the gateway receives: the invocation's request, or, for a
        /// schema the routed model cannot enforce natively, the same request
        /// as text with the schema as an instruction.
        var request: AgentRequest
    }

    func route(
        _ request: AgentModelRouteRequest
    ) throws -> AgentModelRouteResult {
        do {
            let result = try router.route(
                request,
                catalog: routableProfiles
            )
            let selected = result.route.profile
            guard result.route.purpose == request.selection.purpose else {
                throw Rejection.purpose_mismatch
            }
            guard let registered = routableProfiles.profilesByIdentifier[selected.identifier] else {
                throw Rejection.unknown_profile(selected.identifier)
            }
            guard selected == registered else {
                throw Rejection.altered_profile(selected.identifier)
            }
            guard registered.supports(request.selection) else {
                throw Rejection.ineligible_profile(selected.identifier)
            }
            return result
        } catch let error as AgentModelRoutingError {
            switch error {
            case .noRoute:
                try diagnoseUnavailableSelection(
                    request.selection
                )
                throw error

            default:
                throw error
            }
        }
    }

    func diagnoseUnavailableSelection(
        _ selection: AgentModelSelection
    ) throws {
        if let constrainedProfiles = selection.constraints.profiles,
           constrainedProfiles.count == 1,
           let profile = constrainedProfiles.first
        {
            try diagnoseProfile(
                profile
            )
        }

        if let constrainedGateways = selection.constraints.gateways,
           constrainedGateways.count == 1,
           let gateway = constrainedGateways.first
        {
            try diagnoseGateway(
                gateway
            )
        }

        if let profile = selection.preferences.profile {
            try diagnoseProfile(
                profile
            )
        }

        if let gateway = selection.preferences.gateway {
            try diagnoseGateway(
                gateway
            )
        }
    }

    func diagnoseProfile(
        _ identifier: AgentModelProfileIdentifier
    ) throws {
        guard let profile = profiles.profilesByIdentifier[identifier] else {
            throw AgentModelRoutingError.profileNotFound(
                identifier
            )
        }

        let gateway = profile.gateway.id

        if let reason = gateways.unavailability(
            for: gateway
        ) {
            throw AgentModelRoutingError.profileUnavailable(
                profile: identifier,
                gateway: gateway,
                reason: reason
            )
        }

        guard gateways.contains(gateway) else {
            throw AgentModelRoutingError.gatewayNotFound(
                gateway
            )
        }
    }

    func diagnoseGateway(
        _ identifier: AgentModelGatewayIdentifier
    ) throws {
        if let reason = gateways.unavailability(
            for: identifier
        ) {
            throw AgentModelRoutingError.gatewayUnavailable(
                gateway: identifier,
                reason: reason
            )
        }

        guard gateways.contains(identifier) else {
            throw AgentModelRoutingError.gatewayNotFound(
                identifier
            )
        }
    }

    func prepare(
        _ invocation: AgentModelInvocation
    ) throws -> PreparedInvocation {
        // A response schema does not override the purpose's model binding:
        // routing needs text, and a model without native structured output
        // gets the schema as an instruction instead. Requirements the
        // selection itself declares still hold.
        var selection = invocation.selection
        selection.requirements = selection.requirements.merging(
            .init(
                capabilities:
                    invocation.request.responseFormat
                        .requiredCapabilities
                        .subtracting([.structured_output])
            )
        )

        let resolution = try selectionResolver.resolve(
            selection
        )
        var requestMetadata = invocation.request.metadata
        requestMetadata.merge(
            invocation.metadata
        ) { _, new in
            new
        }

        let routed = try route(
            .init(
                selection: resolution.selection,
                metadata: requestMetadata
            )
        )

        var request = invocation.request
        if case .jsonschema(let schema) = request.responseFormat {
            let contract = AgentOutputContract(schema: schema)
            let representation = contract.representation(for: routed.route.profile)
            request = try contract.requesting(request, as: representation)
            requestMetadata["output_representation"] = representation.rawValue
        }

        return .init(
            routeResult: .init(
                route: routed.route,
                diagnostics:
                    resolution.diagnostics
                    + routed.diagnostics
            ),
            requestMetadata: requestMetadata,
            request: request
        )
    }

    @discardableResult
    func record(
        _ routeResult: AgentModelRouteResult,
        requestMetadata: [String: String],
        response: AgentResponse
    ) async throws -> AgentModelRouteRecord {
        let record = AgentModelRouteRecord(
            route: routeResult.route,
            diagnostics: routeResult.diagnostics,
            requestMetadata: requestMetadata,
            responseMetadata: response.metadata,
            usage: response.usage
        )

        try await ledger?.record(
            record
        )

        return record
    }
}

public extension ModelBroker {
    enum Rejection: Swift.Error, Sendable, Hashable {
        case purpose_mismatch
        case unknown_profile(AgentModelProfileIdentifier)
        case altered_profile(AgentModelProfileIdentifier)
        case ineligible_profile(AgentModelProfileIdentifier)
    }
}
