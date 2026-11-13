import Agentic
import Primitives
import Schema
import Testing

extension ExecutionTesting {
    static func runFunctionCallResolver() async throws -> [TestDiagnostic] {
        let probe = FunctionCallResolverProbe()
        let registry = try functionCallResolverRegistry(
            probe: probe
        )

        let observeResolver = GovernedFunctionCallResolver(
            registry: registry,
            visibleToolIdentifiers: [
                "resolver_observe",
            ],
            policy: .init(
                autonomyMode: .auto_observe
            )
        )

        let observeResult = try await observeResolver.resolve(
            try functionCallResolverCall(
                id: "resolver-observe-call",
                name: "resolver_observe"
            )
        )

        try Expect.equal(
            observeResult.isError,
            false,
            "exposed observe call resolves through governed execution"
        )
        try Expect.equal(
            await probe.invocationCount(),
            1,
            "observe call executes exactly once"
        )

        do {
            _ = try await observeResolver.resolve(
                try functionCallResolverCall(
                    id: "resolver-unexposed-call",
                    name: "resolver_mutate"
                )
            )

            throw FunctionCallResolverFlowFailure
                .expectedUnexposedToolRejection
        } catch FunctionCallResolutionError.toolNotVisible(let tool) {
            try Expect.equal(
                tool.rawValue,
                "resolver_mutate",
                "resolver rejects registered but unexposed model calls"
            )
        }

        try Expect.equal(
            await probe.invocationCount(),
            1,
            "unexposed call never reaches execution"
        )

        let approvedResolver = GovernedFunctionCallResolver(
            registry: registry,
            visibleToolIdentifiers: [
                "resolver_mutate",
            ],
            policy: .init(
                autonomyMode: .auto_observe
            ),
            approvalHandler: FunctionCallResolverApprovalHandler(
                decision: .approved
            )
        )

        let approvedResult = try await approvedResolver.resolve(
            try functionCallResolverCall(
                id: "resolver-approved-call",
                name: "resolver_mutate"
            )
        )

        try Expect.equal(
            approvedResult.isError,
            false,
            "in-process human approval returns the executed tool result"
        )
        try Expect.equal(
            await probe.invocationCount(),
            2,
            "approved bounded mutation executes exactly once"
        )

        let unresolvedResolver = GovernedFunctionCallResolver(
            registry: registry,
            visibleToolIdentifiers: [
                "resolver_mutate",
            ],
            policy: .init(
                autonomyMode: .auto_observe
            )
        )

        do {
            _ = try await unresolvedResolver.resolve(
                try functionCallResolverCall(
                    id: "resolver-needs-human-call",
                    name: "resolver_mutate"
                )
            )

            throw FunctionCallResolverFlowFailure
                .expectedNeedsHumanReview
        } catch FunctionCallResolutionError.needsHumanReview(let review) {
            try Expect.equal(
                review.requirement,
                .needs_human_review,
                "resolver preserves unresolved human review for durable fallback"
            )
            try Expect.equal(
                review.invocation.tool.rawValue,
                "resolver_mutate",
                "resolver preserves the pending tool call"
            )
        }

        try Expect.equal(
            await probe.invocationCount(),
            2,
            "unresolved human review never executes the tool"
        )

        let deniedResolver = GovernedFunctionCallResolver(
            registry: registry,
            visibleToolIdentifiers: [
                "resolver_mutate",
            ],
            policy: .init(
                autonomyMode: .auto_observe
            ),
            approvalHandler: FunctionCallResolverApprovalHandler(
                decision: .denied
            )
        )

        let deniedResult = try await deniedResolver.resolve(
            try functionCallResolverCall(
                id: "resolver-denied-call",
                name: "resolver_mutate"
            )
        )

        try Expect.equal(
            deniedResult.isError,
            true,
            "denial becomes a terminal model-facing error result"
        )
        try Expect.equal(
            await probe.invocationCount(),
            2,
            "denial never executes the tool"
        )

        return [
            .field(
                "cases",
                "observe,exposure,approved,needshuman,denied"
            ),
            .field(
                "executions",
                "\(await probe.invocationCount())"
            ),
        ]
    }
}

private actor FunctionCallResolverProbe {
    private var count = 0

    func recordInvocation() {
        count += 1
    }

    func invocationCount() -> Int {
        count
    }
}

private struct FunctionCallResolverProbeInput:
    Sendable,
    Codable,
    JSONSchemaProviding
{
    static var jsonschema: JSONSchema {
        .object {}
    }
}

private protocol FunctionCallResolverProbeIdentity {
    static var definition: ToolDefinition { get }
}

private enum ResolverObserveToolIdentity:
    FunctionCallResolverProbeIdentity
{
    static let definition = ToolDefinition(
        identifier: "resolver_observe",
        purpose: "Observe resolver fixture.",
        risk: .observe
    )
}

private enum ResolverMutateToolIdentity:
    FunctionCallResolverProbeIdentity
{
    static let definition = ToolDefinition(
        identifier: "resolver_mutate",
        purpose: "Bounded mutation resolver fixture.",
        risk: .boundedmutate
    )
}

private struct FunctionCallResolverProbeTool<
    Identity: FunctionCallResolverProbeIdentity
>: Tool {
    typealias Input = FunctionCallResolverProbeInput
    typealias Output = FunctionCallResolverProbeInput

    static var definition: ToolDefinition {
        Identity.definition
    }

    let probe: FunctionCallResolverProbe

    func call(
        _ input: Input,
        in _: ToolContext
    ) async throws -> Output {
        await probe.recordInvocation()
        return input
    }
}

private struct FunctionCallResolverApprovalHandler:
    ToolApprovalHandler
{
    let decision: ApprovalDecision

    func decide(
        on review: ToolInvocation.Review
    ) async throws -> ApprovalDecision {
        decision
    }
}

private enum FunctionCallResolverFlowFailure:
    Error
{
    case expectedUnexposedToolRejection
    case expectedNeedsHumanReview
}

private func functionCallResolverRegistry(
    probe: FunctionCallResolverProbe
) throws -> ToolRegistry {
    var registry = ToolRegistry()

    try registry.register(
        FunctionCallResolverProbeTool<
            ResolverObserveToolIdentity
        >(
            probe: probe
        )
    )
    try registry.register(
        FunctionCallResolverProbeTool<
            ResolverMutateToolIdentity
        >(
            probe: probe
        )
    )

    return registry
}

private func functionCallResolverCall(
    id: String,
    name: String
) throws -> FunctionCall {
    FunctionCall(
        id: id,
        name: name,
        input: .object([
            "arguments": try JSONValue.encoding(
                FunctionCallResolverProbeInput()
            ),
        ])
    )
}
