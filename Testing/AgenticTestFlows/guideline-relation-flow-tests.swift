import Agentic
import Foundation
import Guidelines
import Primitives
import TestFlows

extension AgenticFlowTesting {
    static func runGuidelineRelationIdentity() async throws -> [TestFlowDiagnostic] {
        let guideline = try guidelineFixture()

        let relation = AgentGuidelineRelation(
            .addresses,
            guideline: guideline,
            reasoning: "Exercise typed guideline identity."
        )

        try Expect.equal(
            relation.reference.rawValue,
            guideline.reference,
            "relation retains the canonical guideline reference"
        )

        try Expect.equal(
            relation.relationship,
            .addresses,
            "relation retains its semantic relationship"
        )

        let historical: GuidelineReference =
            "historical.guideline.reference"

        try Expect.equal(
            historical.rawValue,
            "historical.guideline.reference",
            "GuidelineReference remains an open durable identifier"
        )

        return [
            .field(
                "reference",
                relation.reference.rawValue
            ),
            .field(
                "relationship",
                relation.relationship.rawValue
            ),
        ]
    }

    static func runGuidelineRelationCodableDefaults() async throws -> [TestFlowDiagnostic] {
        let relation = try guidelineFixtureRelation()

        let plan = AgentToolPlan(
            id: "guideline-codable-plan",
            root: .call(
                try guidelineProbeCall()
            ),
            guidelineRelations: [
                relation,
            ]
        )

        let legacyPlan = try JSONDecoder().decode(
            AgentToolPlan.self,
            from: removingKey(
                "guidelineRelations",
                from: JSONEncoder().encode(
                    plan
                )
            )
        )

        try Expect.equal(
            legacyPlan.guidelineRelations,
            [],
            "legacy AgentToolPlan JSON defaults missing guideline relations to empty"
        )

        let review = ToolInvocation.Review(
            call: try guidelineProbeCall(),
            preflight: ToolPreflight(
                toolName: "guideline_probe",
                risk: .observe,
                summary: "Guideline review compatibility fixture."
            ),
            requirement: .no_approval_needed,
            guidelineRelations: [
                relation,
            ]
        )

        let legacyReview = try JSONDecoder().decode(
            ToolInvocation.Review.self,
            from: removingKey(
                "guidelineRelations",
                from: JSONEncoder().encode(
                    review
                )
            )
        )

        try Expect.equal(
            legacyReview.guidelineRelations,
            [],
            "legacy ToolInvocation.Review JSON defaults missing guideline relations to empty"
        )

        return [
            .field(
                "plan_relations",
                "\(legacyPlan.guidelineRelations.count)"
            ),
            .field(
                "review_relations",
                "\(legacyReview.guidelineRelations.count)"
            ),
        ]
    }

    static func runGuidelineRelationPlanPropagation() async throws -> [TestFlowDiagnostic] {
        let relation = try guidelineFixtureRelation()

        let invoker = ToolInvoker(
            registry: .init(
                tools: [
                    GuidelineProbeTool(),
                ]
            ),
            policy: .init(
                autonomyMode: .auto_observe
            )
        )

        let result = try await invoker.invoke(
            AgentToolPlan(
                id: "guideline-plan-propagation",
                root: .call(
                    try guidelineProbeCall()
                ),
                guidelineRelations: [
                    relation,
                ]
            )
        )

        try Expect.equal(
            result.outcome,
            .succeeded,
            "guideline rationale does not alter ordinary observe execution"
        )

        guard let invocation = result.records.first?.invocation else {
            throw FlowTestError.unexpectedResult(
                "Expected one governed guideline probe invocation."
            )
        }

        try Expect.equal(
            invocation.review.guidelineRelations,
            [
                relation,
            ],
            "plan guideline relations propagate into ToolInvocation.Review"
        )

        try Expect.equal(
            invocation.review.requirement,
            .no_approval_needed,
            "guideline rationale does not alter policy evaluation"
        )

        try Expect.equal(
            invocation.review.preflight.toolName,
            "guideline_probe",
            "tool preflight remains the tool-produced operational preflight"
        )

        return [
            .field(
                "reference",
                relation.reference.rawValue
            ),
            .field(
                "outcome",
                result.outcome.rawValue
            ),
        ]
    }

    static func runGuidelineRelationApprovalReviewBoundary() async throws -> [TestFlowDiagnostic] {
        let relation = try guidelineFixtureRelation()
        let probe = GuidelineApprovalReviewProbe()

        let invoker = ToolInvoker(
            registry: .init(
                tools: [
                    GuidelineProbeTool(),
                ]
            ),
            policy: .init(
                autonomyMode: .suggest_only
            )
        )

        let result = try await invoker.invoke(
            AgentToolPlan(
                id: "guideline-approval-review-boundary",
                root: .call(
                    try guidelineProbeCall()
                ),
                guidelineRelations: [
                    relation,
                ]
            ),
            approvalHandler:
                GuidelineReviewApprovalHandler(
                    probe: probe
                )
        )

        try Expect.equal(
            await probe.guidelineRelations(),
            [
                relation,
            ],
            "approval handlers can receive the complete ToolInvocation.Review rationale"
        )

        try Expect.equal(
            result.outcome,
            .succeeded,
            "review-aware approval preserves ordinary approval execution"
        )

        return [
            .field(
                "reference",
                relation.reference.rawValue
            ),
            .field(
                "outcome",
                result.outcome.rawValue
            ),
        ]
    }
}

private actor GuidelineApprovalReviewProbe {
    private var relations: [AgentGuidelineRelation] = []

    func record(
        _ review: ToolInvocation.Review
    ) {
        relations = review.guidelineRelations
    }

    func guidelineRelations() -> [AgentGuidelineRelation] {
        relations
    }
}

private struct GuidelineReviewApprovalHandler:
    ToolApprovalHandler
{
    let probe: GuidelineApprovalReviewProbe

    func decide(
        on review: ToolInvocation.Review
    ) async throws -> ApprovalDecision {
        await probe.record(
            review
        )

        return .approved
    }
}

private struct GuidelineProbeInput:
    Sendable,
    Codable,
    Hashable
{}

private struct GuidelineProbeTool:
    AgentTool
{
    let identifier: AgentToolIdentifier =
        "guideline_probe"

    let description =
        "Proves typed guideline rationale propagation."

    let risk: ActionRisk =
        .observe

    func preflight(
        input _: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        ToolPreflight(
            toolName: identifier.rawValue,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            summary: description
        )
    }

    func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        try await call(
            input: input,
            context: .init(
                workspace: workspace
            )
        )
    }

    func call(
        input: JSONValue,
        context _: AgentToolExecutionContext
    ) async throws -> JSONValue {
        input
    }
}

private func guidelineProbeCall() throws -> AgentToolCall {
    AgentToolCall(
        id: "guideline-probe-call",
        name: "guideline_probe",
        input: try JSONToolBridge.encode(
            GuidelineProbeInput()
        )
    )
}

private func guidelineFixture() throws -> Guideline {
    guard let guideline = Guideline.all.first else {
        throw FlowTestError.unexpectedResult(
            "Expected at least one authored Guideline fixture."
        )
    }

    return guideline
}

private func guidelineFixtureRelation() throws -> AgentGuidelineRelation {
    AgentGuidelineRelation(
        .addresses,
        guideline: try guidelineFixture(),
        reasoning: "Test typed Agentic guideline rationale."
    )
}

private func removingKey(
    _ key: String,
    from data: Data
) throws -> Data {
    guard var object = try JSONSerialization.jsonObject(
        with: data
    ) as? [String: Any] else {
        throw FlowTestError.unexpectedResult(
            "Expected a top-level JSON object."
        )
    }

    object.removeValue(
        forKey: key
    )

    return try JSONSerialization.data(
        withJSONObject: object
    )
}
