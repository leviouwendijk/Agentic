import Agentic
import Foundation
import Testing

private struct TypedAdapterFixtureInference: Inference {
    typealias Input = String
    typealias Output = String
    static let definition = InferenceDefinition(
        identifier: "typed_adapter_fixture",
        purpose: "Test captured per-invocation decoding."
    )
}

private struct OtherAdapterFixtureInference: Inference {
    typealias Input = String
    typealias Output = String
    static let definition = InferenceDefinition(
        identifier: "typed_adapter_other",
        purpose: "Must not match the targeted adapter."
    )
}

@Domain
private enum AdapterFlowDomain {}

extension AdapterFlowDomain.Adapters {
    @Adapter
    struct Prefix: InferenceAdapterFor {
        typealias Target = TypedAdapterFixtureInference

        func prepare(
            input: String,
            realization _: InferenceRealizationConfiguration
        ) throws -> PreparedInference<String> {
            PreparedInference(
                adaptation: .init(request: AgentRequest(messages: [])),
                decode: { _ in input }
            )
        }
    }
}

enum TypedInferenceAdapterFlowTests {
    static let all: [TestFlow] = [
        TestFlow("typed-inference-adapter-eligibility-and-capture", tags: ["adapters","typed"]) {
            try verify()
        },
    ]

    static func verify() throws -> [TestDiagnostic] {
        let adapter = TypedInferenceAdapter(AdapterFlowDomain.Adapters.Prefix())
        var catalog = InferenceAdapterCatalog()
        try catalog.register(adapter)
        let selected = try catalog.require(adapter.identifier)
        let a = try selected.prepareInvocation(
            TypedAdapterFixtureInference.self,
            input: "first", realization: .init(strategy: .direct, instructions: "", budget: .singleAttempt)
        )
        let b = try selected.prepareInvocation(
            TypedAdapterFixtureInference.self,
            input: "second", realization: .init(strategy: .direct, instructions: "", budget: .singleAttempt)
        )
        let response = AgentResponse(message: Message(role: .assistant, content: .init(text: "ignored")), stopReason: .end_turn)
        try Expect.equal(try a.decode(response), "first", "first invocation binding retained")
        try Expect.equal(try b.decode(response), "second", "second invocation binding isolated")

        do {
            _ = try selected.prepareInvocation(
                OtherAdapterFixtureInference.self,
                input: "wrong", realization: .init(strategy: .direct, instructions: "", budget: .singleAttempt)
            )
            throw TestFlowAssertionFailure(label: "incompatible adapter", message: "Expected mismatch")
        } catch is TypedInferenceAdapterError {
            // Expected typed eligibility failure before any model transport.
        }

        try Expect.true(
            AdapterFlowDomain.catalog.adapters.contains(where: {
                $0.identifier == adapter.identifier
            }),
            "@Adapter contributes domain-specific metadata"
        )
        return [.field("adapter", adapter.identifier.rawValue)]
    }
}
