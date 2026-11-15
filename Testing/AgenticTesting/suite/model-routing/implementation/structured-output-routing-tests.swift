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
        try Expect.equal(prompted.route.requestMetadata["structured_output"], "prompted", "the route record says so")

        let enforced = try await broker.buffered(.init(request: request(), selection: selection("native.gateway")))
        try Expect.equal(enforced.route.route.profile.identifier, native.identifier, "native route")
        let sentNative = try Expect.notNil(await recorder.requests.last, "native gateway was called")
        try Expect.equal(sentNative.responseFormat, .jsonschema(schema), "native structured output is kept")
        try Expect.equal(sentNative.messages.count, 2, "no instruction added")

        return []
    }
}

private actor StructuredRoutingRecorder {
    var requests: [AgentRequest] = []
    func record(_ request: AgentRequest) { requests.append(request) }
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
