import Agentic
import Testing

private enum AgenticTestingSmokeError: Error {
    case fixture
}

func runAgenticTestingToolLifecycleSmoke()
    async throws
    -> [TestDiagnostic]
{
    let tool = SmokeTool()
    let input = SmokeToolInput(
        rawValue: "tool-lifecycle-smoke"
    )
    let characterized = try await DirectToolTest.characterize(
        tool,
        input: input
    )

    try Expect.equal(
        characterized.projection?.status,
        "smoke",
        "Tool characterization includes result projection"
    )

    let projected = try DirectToolTest.process(
        tool,
        output: characterized.output,
        input: input
    )

    try Expect.equal(
        projected.projection?.summary,
        "tool-lifecycle-smoke:tool-lifecycle-smoke",
        "direct Tool projection preserves typed input and output"
    )

    let classified = DirectToolTest.classify(
        tool,
        error: AgenticTestingSmokeError.fixture,
        phase: .call,
        input: input
    )

    try Expect.equal(
        classified.incident == nil,
        true,
        "default Tool recovery classification remains observable"
    )

    let failure = ToolCall.Failure(
        tool: SmokeTool.definition.identifier,
        toolCallID: "tool-lifecycle-smoke",
        phase: .call,
        message: "fixture failure",
        errorType: "AgenticTestingSmokeError"
    )
    let reconciled = try await DirectToolTest.reconcile(
        tool,
        input: input,
        after: failure
    )

    let reconciliationIsNotApplied: Bool
    switch reconciled.reconciliation {
    case .some(.not_applied):
        reconciliationIsNotApplied = true

    default:
        reconciliationIsNotApplied = false
    }

    try Expect.equal(
        reconciliationIsNotApplied,
        true,
        "direct Tool reconciliation preserves authored reconciliation state"
    )

    return [
        .field(
            "tool",
            characterized.definition.identifier.rawValue
        ),
        .field(
            "projection",
            characterized.projection?.status ?? "nil"
        ),
        .field(
            "classified",
            classified.incident == nil ? "nil" : "incident"
        ),
        .field(
            "reconciliation",
            reconciliationIsNotApplied ? "not_applied" : "unexpected"
        ),
    ]
}

func runScriptedModelResponsesSmoke()
    async throws
    -> [TestDiagnostic]
{
    let firstResponse = AgentResponse(
        message: AgentMessage(
            role: .assistant,
            text: "first"
        ),
        stopReason: .end_turn
    )
    let secondResponse = AgentResponse(
        message: AgentMessage(
            role: .assistant,
            text: "second"
        ),
        stopReason: .end_turn
    )
    let scriptedFailure = ScriptedModelFailure(
        message: "scripted failure"
    )
    let responses = ScriptedModelResponses(
        buffered: [
            .success(firstResponse),
            .failure(scriptedFailure),
            .success(secondResponse),
        ],
        stream: [
            .success([
                .messagedelta(.text("partial")),
                .completed(secondResponse),
            ]),
            .failure(scriptedFailure),
        ]
    )
    let gateway = ScriptedModelGateway(
        responses: responses
    )
    let profile = AgentModelProfile(
        identifier: .init(
            rawValue: "scripted_testing_profile"
        ),
        gatewayIdentifier: gateway.identifier,
        model: "fixture"
    )
    let route = AgentModelRoute(
        purpose: .executor,
        profile: profile
    )
    let request = AgentRequest(
        messages: [
            AgentMessage(
                role: .user,
                text: "scripted request"
            ),
        ]
    )

    let observedFirst = try await gateway.respond(
        request: request,
        route: route
    )

    try Expect.equal(
        observedFirst,
        firstResponse,
        "scripted buffered responses are consumed in order"
    )

    var bufferedFailureObserved = false
    do {
        _ = try await gateway.respond(
            request: request,
            route: route
        )
    } catch let failure as ScriptedModelFailure {
        bufferedFailureObserved = failure == scriptedFailure
    }

    try Expect.equal(
        bufferedFailureObserved,
        true,
        "scripted buffered failures are emitted in order"
    )

    let observedSecond = try await gateway.respond(
        request: request,
        route: route
    )

    try Expect.equal(
        observedSecond,
        secondResponse,
        "script continues after an authored failure"
    )

    var observedStream: [AgentStreamEvent] = []
    for try await event in gateway.respond(
        request: request,
        route: route,
        delivery: .stream
    ) {
        observedStream.append(event)
    }

    try Expect.equal(
        observedStream,
        [
            .messagedelta(.text("partial")),
            .completed(secondResponse),
        ],
        "scripted stream events preserve authored order"
    )

    var streamFailureObserved = false
    do {
        for try await _ in gateway.respond(
            request: request,
            route: route,
            delivery: .stream
        ) {}
    } catch let failure as ScriptedModelFailure {
        streamFailureObserved = failure == scriptedFailure
    }

    try Expect.equal(
        streamFailureObserved,
        true,
        "scripted stream failures are emitted in order"
    )

    var exhaustionObserved = false
    do {
        _ = try await gateway.respond(
            request: request,
            route: route
        )
    } catch let failure as ScriptedModelFailure {
        exhaustionObserved = failure == .responsesExhausted(.buffered)
    }

    try Expect.equal(
        exhaustionObserved,
        true,
        "scripted response exhaustion fails explicitly"
    )

    let invocations = await responses.recordedInvocations()
    let remainingBuffered = await responses.remainingBufferedResponseCount()
    let remainingStream = await responses.remainingStreamResponseCount()

    try Expect.equal(
        invocations.map(\.delivery),
        [
            .buffered,
            .buffered,
            .buffered,
            .stream,
            .stream,
            .buffered,
        ],
        "scripted model responses record delivery order"
    )
    try Expect.equal(
        remainingBuffered,
        0,
        "buffered script is consumed"
    )
    try Expect.equal(
        remainingStream,
        0,
        "stream script is consumed"
    )

    return [
        .field(
            "invocations",
            String(invocations.count)
        ),
        .field(
            "buffered_remaining",
            String(remainingBuffered)
        ),
        .field(
            "stream_remaining",
            String(remainingStream)
        ),
        .field(
            "exhaustion",
            String(exhaustionObserved)
        ),
    ]
}
