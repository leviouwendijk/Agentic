import Agentic
import Foundation
import TestFlows

extension AgenticFlowTesting {
    static func runModelRoutePlannerPrefersDefault() async throws -> [TestFlowDiagnostic] {
        let plannerID = AgentModelProfileIdentifier(
            "test:planner:opus"
        )
        let researcherID = AgentModelProfileIdentifier(
            "test:researcher:sonnet"
        )
        let catalog = try AgentModelProfileCatalog(
            profiles: [
                plannerProfile(
                    plannerID
                ),
                researcherProfile(
                    researcherID
                ),
            ]
        )
        let router = StaticAgentModelRouter(
            defaults: [
                .planner: plannerID,
                .researcher: researcherID,
            ]
        )
        let result = try router.route(
            .init(
                request: routeRequest(),
                policy: .planner
            ),
            catalog: catalog
        )

        try Expect.equal(
            result.route.purpose,
            .planner,
            "route purpose"
        )
        try Expect.equal(
            result.route.profile.identifier,
            plannerID,
            "planner profile"
        )
        try Expect.equal(
            result.reasons.joined(separator: ","),
            "purpose_default",
            "route reason"
        )

        return [
            .field(
                "purpose",
                result.route.purpose.rawValue
            ),
            .field(
                "profile",
                result.route.profile.identifier.rawValue
            ),
            .field(
                "model",
                result.route.profile.model
            ),
        ]
    }

    static func runModelRouteResearcherPrefersDefault() async throws -> [TestFlowDiagnostic] {
        let plannerID = AgentModelProfileIdentifier(
            "test:planner:opus"
        )
        let researcherID = AgentModelProfileIdentifier(
            "test:researcher:sonnet"
        )
        let catalog = try AgentModelProfileCatalog(
            profiles: [
                plannerProfile(
                    plannerID
                ),
                researcherProfile(
                    researcherID
                ),
            ]
        )
        let router = StaticAgentModelRouter(
            defaults: [
                .planner: plannerID,
                .researcher: researcherID,
            ]
        )
        let result = try router.route(
            .init(
                request: routeRequest(),
                policy: .researcher
            ),
            catalog: catalog
        )

        try Expect.equal(
            result.route.purpose,
            .researcher,
            "route purpose"
        )
        try Expect.equal(
            result.route.profile.identifier,
            researcherID,
            "researcher profile"
        )
        try Expect.equal(
            result.reasons.joined(separator: ","),
            "purpose_default",
            "route reason"
        )

        return [
            .field(
                "purpose",
                result.route.purpose.rawValue
            ),
            .field(
                "profile",
                result.route.profile.identifier.rawValue
            ),
            .field(
                "model",
                result.route.profile.model
            ),
        ]
    }

    static func runModelRouteResearcherSelectsNovaProCandidate() async throws -> [TestFlowDiagnostic] {
        let novaProID = AgentModelProfileIdentifier(
            "test:researcher:nova-pro"
        )
        let catalog = try AgentModelProfileCatalog(
            profiles: [
                researchDelegateProfile(
                    novaProID
                ),
            ]
        )
        let router = StaticAgentModelRouter()
        let result = try router.route(
            .init(
                request: routeRequest(),
                policy: .researcher
            ),
            catalog: catalog
        )

        try Expect.equal(
            result.route.purpose,
            .researcher,
            "route purpose"
        )
        try Expect.equal(
            result.route.profile.identifier,
            novaProID,
            "research delegate profile"
        )
        try Expect.equal(
            result.reasons.joined(separator: ","),
            "purpose_match",
            "route reason"
        )

        return [
            .field(
                "purpose",
                result.route.purpose.rawValue
            ),
            .field(
                "profile",
                result.route.profile.identifier.rawValue
            ),
            .field(
                "model",
                result.route.profile.model
            ),
        ]
    }

    static func runModelRoutePurposeCodableRoundTrip() async throws -> [TestFlowDiagnostic] {
        let values: [AgentModelRoutePurpose] = [
            .planner,
            .researcher,
        ]
        let data = try JSONEncoder().encode(
            values
        )
        let decoded = try JSONDecoder().decode(
            [AgentModelRoutePurpose].self,
            from: data
        )

        try Expect.equal(
            decoded,
            values,
            "route purpose codable round trip"
        )

        return [
            .field(
                "purposes",
                decoded.map(\.rawValue).joined(separator: ",")
            ),
        ]
    }
}

private extension AgenticFlowTesting {
    static func routeRequest() -> AgentRequest {
        .init(
            messages: [
                .init(
                    role: .user,
                    text: "route this request"
                ),
            ]
        )
    }

    static func plannerProfile(
        _ id: AgentModelProfileIdentifier
    ) -> AgentModelProfile {
        .init(
            identifier: id,
            adapterIdentifier: .init(
                "test"
            ),
            model: "claude-opus-planner",
            title: "Planner",
            purposes: [
                .planner,
            ],
            capabilities: [
                .text,
                .reasoning,
            ],
            cost: .premium,
            latency: .medium,
            privacy: .private_cloud
        )
    }

    static func researcherProfile(
        _ id: AgentModelProfileIdentifier
    ) -> AgentModelProfile {
        .init(
            identifier: id,
            adapterIdentifier: .init(
                "test"
            ),
            model: "claude-sonnet-researcher",
            title: "Researcher",
            purposes: [
                .researcher,
            ],
            capabilities: [
                .text,
                .reasoning,
                .structured_output,
            ],
            cost: .premium,
            latency: .medium,
            privacy: .private_cloud
        )
    }

    static func researchDelegateProfile(
        _ id: AgentModelProfileIdentifier
    ) -> AgentModelProfile {
        .init(
            identifier: id,
            adapterIdentifier: .init(
                "test"
            ),
            model: "nova-pro-research-delegate",
            title: "Research Delegate",
            purposes: [
                .researcher,
                .summarizer,
            ],
            capabilities: [
                .text,
                .reasoning,
                .structured_output,
            ],
            cost: .balanced,
            latency: .medium,
            privacy: .private_cloud
        )
    }
}
