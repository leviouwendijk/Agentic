import Agentic
import Primitives
import Schema
import Testing

extension ExecutionTesting {
    static func runFunctionCallResolverObserver()
        async throws
        -> [TestDiagnostic]
    {
        let probe = FunctionCallResolverObserverProbe()
        let observer = FunctionCallResolverObserverStore()
        let registry = try functionCallResolverObserverRegistry(
            probe: probe
        )

        let observeResolver = GovernedFunctionCallResolver(
            registry: registry,
            visibleToolIdentifiers: [
                "resolver_observer_observe",
            ],
            policy: .init(
                autonomyMode: .auto_observe
            ),
            resolutionObserver: { invocation in
                await observer.append(
                    invocation
                )
            }
        )

        _ = try await observeResolver.resolve(
            try functionCallResolverObserverCall(
                id: "resolver-observer-observe-call",
                name: "resolver_observer_observe"
            )
        )

        let observedExecution = try Expect.notNil(
            await observer.last(),
            "resolver observer receives completed invocation"
        )

        try Expect.equal(
            observedExecution.decision,
            .approved,
            "resolver observer sees approved invocation"
        )
        try Expect.equal(
            observedExecution.execution?.result.call.id,
            "resolver-observer-observe-call",
            "resolver observer sees the exact executed result"
        )
        try Expect.equal(
            await probe.invocationCount(),
            1,
            "observer does not alter normal execution"
        )

        await observer.removeAll()

        let reviewResolver = GovernedFunctionCallResolver(
            registry: registry,
            visibleToolIdentifiers: [
                "resolver_observer_mutate",
            ],
            policy: .init(
                autonomyMode: .auto_observe
            ),
            resolutionObserver: { invocation in
                await observer.append(
                    invocation
                )
            }
        )

        do {
            _ = try await reviewResolver.resolve(
                try functionCallResolverObserverCall(
                    id: "resolver-observer-review-call",
                    name: "resolver_observer_mutate"
                )
            )

            throw FunctionCallResolverObserverFailure
                .expectedNeedsHumanReview
        } catch FunctionCallResolutionError.needsHumanReview(_) {
        }

        let observedReview = try Expect.notNil(
            await observer.last(),
            "resolver observer receives unresolved review invocation"
        )

        try Expect.equal(
            observedReview.decision,
            .needshuman,
            "resolver observer sees unresolved human review"
        )
        try Expect.equal(
            observedReview.execution,
            nil,
            "unresolved human review remains unexecuted"
        )
        try Expect.equal(
            await probe.invocationCount(),
            1,
            "unresolved review does not execute the mutation"
        )

        return [
            .field(
                "completed_decision",
                observedExecution.decision.rawValue
            ),
            .field(
                "review_decision",
                observedReview.decision.rawValue
            ),
        ]
    }
}

private actor FunctionCallResolverObserverStore {
    private var invocations: [ToolInvocation.Result] = []

    func append(
        _ invocation: ToolInvocation.Result
    ) {
        invocations.append(
            invocation
        )
    }

    func last() -> ToolInvocation.Result? {
        invocations.last
    }

    func removeAll() {
        invocations.removeAll()
    }
}

private actor FunctionCallResolverObserverProbe {
    private var count = 0

    func recordInvocation() {
        count += 1
    }

    func invocationCount() -> Int {
        count
    }
}

private struct FunctionCallResolverObserverInput:
    Sendable,
    Codable,
    JSONSchemaProviding
{
    static var jsonschema: JSONSchema {
        .object {}
    }
}

private protocol FunctionCallResolverObserverIdentity {
    static var definition: ToolDefinition { get }
}

private enum ResolverObserverObserveIdentity:
    FunctionCallResolverObserverIdentity
{
    static let definition = ToolDefinition(
        identifier: "resolver_observer_observe",
        purpose: "Observe resolver observer fixture.",
        risk: .observe
    )
}

private enum ResolverObserverMutateIdentity:
    FunctionCallResolverObserverIdentity
{
    static let definition = ToolDefinition(
        identifier: "resolver_observer_mutate",
        purpose: "Mutate resolver observer fixture.",
        risk: .boundedmutate
    )
}

private struct FunctionCallResolverObserverTool<
    Identity: FunctionCallResolverObserverIdentity
>: Tool {
    typealias Input = FunctionCallResolverObserverInput
    typealias Output = FunctionCallResolverObserverInput

    static var definition: ToolDefinition {
        Identity.definition
    }

    let probe: FunctionCallResolverObserverProbe

    func call(
        _ input: Input,
        in _: ToolContext
    ) async throws -> Output {
        await probe.recordInvocation()
        return input
    }
}

private enum FunctionCallResolverObserverFailure:
    Error
{
    case expectedNeedsHumanReview
}

private func functionCallResolverObserverRegistry(
    probe: FunctionCallResolverObserverProbe
) throws -> ToolRegistry {
    var registry = ToolRegistry()

    try registry.register(
        FunctionCallResolverObserverTool<
            ResolverObserverObserveIdentity
        >(
            probe: probe
        )
    )
    try registry.register(
        FunctionCallResolverObserverTool<
            ResolverObserverMutateIdentity
        >(
            probe: probe
        )
    )

    return registry
}

private func functionCallResolverObserverCall(
    id: String,
    name: String
) throws -> FunctionCall {
    FunctionCall(
        id: id,
        name: name,
        input: .object([
            "arguments": try JSONValue.encoding(
                FunctionCallResolverObserverInput()
            ),
        ])
    )
}
