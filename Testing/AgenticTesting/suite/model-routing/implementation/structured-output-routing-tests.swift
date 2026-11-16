import Agentic
import Schema
import Testing

extension ModelRoutingImplementationTesting {
    /// A response schema does not override the purpose's binding: the
    /// preferred model without native structured output receives the schema
    /// as an instruction; one with it receives the schema natively.
    static func runStructuredOutputRouting() async throws -> [TestDiagnostic] {
        let plain = AgentModelProfile(
            identifier: "plain.profile",
            gatewayIdentifier: "plain.gateway",
            model: "plain-model",
            capabilities: [.text, .tool_use]
        )
        let native = AgentModelProfile(
            identifier: "native.profile",
            gatewayIdentifier: "native.gateway",
            model: "native-model",
            capabilities: [.text, .tool_use, .structured_output]
        )
        let recorder = StructuredRoutingRecorder()
        let broker = ModelBroker(
            profiles: try ProfileCatalog(profiles: [plain, native]),
            gateways: try GatewayCatalog(gateways: [
                StructuredRoutingGateway(identifier: "plain.gateway", recorder: recorder),
                StructuredRoutingGateway(identifier: "native.gateway", recorder: recorder),
            ])
        )
        let schema = JSONSchema.object(properties: [
            .init(name: "summary", schema: .string()),
        ])
        func request() -> AgentRequest {
            .init(
                messages: [
                    .init(role: .system, text: "You are a worker."),
                    .init(role: .user, text: "Report."),
                ],
                responseFormat: .jsonschema(schema)
            )
        }
        func selection(_ gateway: AgentModelGatewayIdentifier) -> AgentModelSelection {
            .init(purpose: .executor, preferences: .init(gateway: gateway))
        }

        let prompted = try await broker.buffered(.init(request: request(), selection: selection("plain.gateway")))
        try Expect.equal(prompted.route.route.profile.identifier, plain.identifier, "the binding wins over the schema")
        let sentPlain = try Expect.notNil(await recorder.requests.last, "plain gateway was called")
        try Expect.equal(sentPlain.responseFormat, .text, "a model without structured output gets text")
        try Expect.equal(sentPlain.messages.map(\.role), [.system, .system, .user], "the schema instruction follows the system prompt")
        try Expect.true(
            sentPlain.messages[1].content.text.contains("\"summary\""),
            "the instruction carries the schema"
        )
        try Expect.equal(prompted.route.requestMetadata["output_representation"], "prompted_json", "the route record says so")

        let enforced = try await broker.buffered(.init(request: request(), selection: selection("native.gateway")))
        try Expect.equal(enforced.route.route.profile.identifier, native.identifier, "native route")
        let sentNative = try Expect.notNil(await recorder.requests.last, "native gateway was called")
        try Expect.equal(sentNative.responseFormat, .jsonschema(schema), "native structured output is kept")
        try Expect.equal(sentNative.messages.count, 2, "no instruction added")

        let countedPlain = try await broker.countInputTokens(
            .init(request: request(), selection: selection("plain.gateway"))
        )
        let countedNative = try await broker.countInputTokens(
            .init(request: request(), selection: selection("native.gateway"))
        )
        try Expect.equal(countedPlain.inputTokens, 17, "Provider count is retained")
        try Expect.equal(countedPlain.route.route.profile.identifier, plain.identifier,
            "Counting honors the purpose's selected gateway")
        try Expect.equal(countedPlain.request.responseFormat, .text,
            "Counting includes prompted JSON adaptation")
        try Expect.equal(countedPlain.request.messages.map(\.content), sentPlain.messages.map(\.content),
            "Counting and generation receive the same adapted content")
        try Expect.equal(countedNative.request.responseFormat, .jsonschema(schema),
            "Counting preserves native output schemas")
        try Expect.equal(countedNative.request.messages.map(\.content), sentNative.messages.map(\.content),
            "Native content is not duplicated for counting")
        try Expect.equal(await recorder.requests.count, 2, "Counting does not generate responses")
        try Expect.equal(await recorder.countRequests.count, 2, "Counts use a separate operation")

        await recorder.configureCount(0)
        let emptyCount = try await broker.countInputTokens(
            .init(request: request(), selection: selection("plain.gateway"))
        )
        try Expect.equal(emptyCount.inputTokens, 0, "Zero is a reported count, not unsupported")
        let unsupported = try await UncountedRoutingResponder().countInputTokens(
            request: request(), route: .init(purpose: .executor, profile: plain), context: .default
        )
        try Expect.equal(unsupported, nil, "Existing providers default to unsupported counting")

        await recorder.configureCount(-1)
        var rejected = false
        do {
            _ = try await broker.countInputTokens(
                .init(request: request(), selection: selection("plain.gateway"))
            )
        } catch let error as AgentModelInvocation.InputCount.Error {
            rejected = error == .negativeInputTokens(-1)
        }
        try Expect.true(rejected, "Invalid provider counts cannot become budget evidence")

        await recorder.configureCount(nil, fails: true)
        var failed = false
        do {
            _ = try await broker.countInputTokens(
                .init(request: request(), selection: selection("plain.gateway"))
            )
        } catch CountingRoutingFixtureError.countFailure {
            failed = true
        }
        try Expect.true(failed, "Count failures propagate without generation or a fake estimate")
        try Expect.equal(await recorder.requests.count, 2, "Failures never fall back to generation")

        return []
    }
}

private actor StructuredRoutingRecorder {
    var requests: [AgentRequest] = []
    var countRequests: [AgentRequest] = []
    private var inputTokens: Int? = 17
    private var countingFails = false
    func record(_ request: AgentRequest) { requests.append(request) }

    func configureCount(_ inputTokens: Int?, fails: Bool = false) {
        self.inputTokens = inputTokens
        countingFails = fails
    }

    func count(_ request: AgentRequest) throws -> Int? {
        countRequests.append(request)
        if countingFails { throw CountingRoutingFixtureError.countFailure }
        return inputTokens
    }
}

private struct StructuredRoutingGateway: AgentModelGateway {
    let identifier: AgentModelGatewayIdentifier
    let recorder: StructuredRoutingRecorder

    var response: AgentModelResponseProviding {
        StructuredRoutingResponder(recorder: recorder)
    }
}

private struct StructuredRoutingResponder: AgentModelResponseProviding {
    let recorder: StructuredRoutingRecorder

    func countInputTokens(
        request: AgentRequest,
        route _: AgentModelRoute,
        context _: AgentModelInvocationContext
    ) async throws -> Int? {
        try await recorder.count(request)
    }

    func buffered(
        request: AgentRequest,
        route _: AgentModelRoute,
        context _: AgentModelInvocationContext
    ) async throws -> AgentResponse {
        await recorder.record(request)
        return .init(message: .init(role: .assistant, text: #"{"summary":"ok"}"#), stopReason: .end_turn)
    }

    func stream(
        request _: AgentRequest,
        route _: AgentModelRoute,
        context _: AgentModelInvocationContext
    ) -> AsyncThrowingStream<AgentStreamEvent, Error> {
        AsyncThrowingStream { $0.finish() }
    }
}

private enum CountingRoutingFixtureError: Error {
    case countFailure
    case unexpectedGeneration
}

private struct UncountedRoutingResponder: AgentModelResponseProviding {
    func buffered(
        request _: AgentRequest,
        route _: AgentModelRoute,
        context _: AgentModelInvocationContext
    ) async throws -> AgentResponse {
        throw CountingRoutingFixtureError.unexpectedGeneration
    }

    func stream(
        request _: AgentRequest,
        route _: AgentModelRoute,
        context _: AgentModelInvocationContext
    ) -> AsyncThrowingStream<AgentStreamEvent, Error> {
        AsyncThrowingStream { $0.finish(throwing: CountingRoutingFixtureError.unexpectedGeneration) }
    }
}
