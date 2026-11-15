import Agentic
import Primitives
import Schema
import Testing

/// The shared output contract and the adapter built on it: the same parse
/// for native and prompted answers, and no hard native requirement.
enum JSONAdapterFlowTests {
    static let all: [TestFlow] = [
        TestFlow(
            "output-contract-parsing",
            tags: ["adapters", "structured-output", "contract"]
        ) {
            try contractParsing()
        },
        TestFlow(
            "json-adapter-flexible",
            tags: ["adapters", "inference", "structured-output"]
        ) {
            try flexibleAdapter()
        },
    ]

    static func contractParsing() throws -> [TestDiagnostic] {
        let contract = AgentOutputContract(schema: JSONSchema.object {
            JSONSchema.property("summary", schema: .string(), required: true)
        })
        let report = JSONValue.object(["summary": .string("done")])

        try Expect.equal(try contract.parse(#"{"summary":"done"}"#).value, report, "a conforming answer")
        try Expect.equal(
            try contract.parse("```json\n{\"summary\":\"done\"}\n```").value,
            report,
            "a fenced answer"
        )
        func failure(_ text: String) -> AgentOutputFailure? {
            do {
                _ = try contract.parse(text)
                return nil
            } catch {
                return error
            }
        }
        try Expect.equal(failure("  "), .empty, "empty")
        try Expect.equal(failure("Done."), .not_json, "prose")
        for (label, text) in [("array", #"["done"]"#), ("missing field", "{}")] {
            guard case .nonconforming? = failure(text) else {
                throw TestFlowAssertionFailure(label: label, message: "expected nonconforming, got \(String(describing: failure(text)))")
            }
        }

        let request = AgentRequest(messages: [
            .init(role: .system, text: "System."),
            .init(role: .user, text: "Go."),
        ])
        let prompted = try contract.requesting(request, as: .prompted_json)
        try Expect.equal(prompted.responseFormat, .text, "prompted JSON travels as text")
        try Expect.equal(prompted.messages.map(\.role), [.system, .system, .user], "instruction after the system prompt")
        let native = try contract.requesting(request, as: .native_schema)
        try Expect.equal(native.responseFormat, .jsonschema(contract.schema), "native keeps the schema")
        try Expect.equal(native.messages.count, 2, "native adds no instruction")
        return []
    }

    static func flexibleAdapter() throws -> [TestDiagnostic] {
        let adapter = JSONAdapter()
        let realization = InferenceRealizationConfiguration(
            strategy: .direct,
            instructions: "Return the normalized value.",
            budget: .singleAttempt
        )
        let adaptation = try adapter.prepare(
            ProbeStructuredInference.self,
            input: .init(value: "hello"),
            realization: realization
        )
        try Expect.equal(adapter.identifier, .json, "json adapter identifier")
        try Expect.false(
            adaptation.requirements.capabilities.contains(.structured_output),
            "no hard native requirement: routing keeps the purpose's model"
        )
        try Expect.equal(
            adaptation.request.responseFormat,
            .jsonschema(String.jsonschema),
            "the schema stays the request's format for the broker to place"
        )
        try Expect.equal(
            try adapter.decode(ProbeStructuredInference.self, response: .init(
                message: .init(role: .assistant, text: "```json\n\"HELLO\"\n```"),
                stopReason: .end_turn
            )),
            "HELLO",
            "a prompted, fenced answer decodes to the typed output"
        )
        return []
    }
}
