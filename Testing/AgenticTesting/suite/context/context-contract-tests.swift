import Agentic
import Foundation
import Testing

enum ContextContractSuite {
    static let testSuite = TestSuite(
        "context-contracts",
        title: "Context pointer, allocation and frame contracts"
    ) {
        Test("heterogeneous-pointers-round-trip") {
            let pointers = [
                Context.Pointer(source: "session/A", record: "message/2", revision: .recorded("v1")),
                Context.Pointer(source: "session/B", record: "run/99", revision: .recorded("v2")),
                Context.Pointer(source: "repo/X", record: "file/Runner.swift", selection: .lines(start: 1, end: 7)),
                Context.Pointer(source: "artifacts", record: "failed-build/19"),
            ]
            let encoded = try JSONEncoder().encode(pointers)
            let decoded = try JSONDecoder().decode([Context.Pointer].self, from: encoded)
            try Expect.equal(decoded, pointers, "Pointers preserve source, selection and version policy")
        }

        Test("frames-retain-message-semantics") {
            let pointer = Context.Pointer(source: "session/A", record: "message/2", revision: .recorded("v1"))
            let original = Message(role: .user, text: "Inspect the mutation failure")
            let frame = Context.Frame(
                workingSetID: "worker",
                items: [.init(allocationID: "a", observed: pointer, messages: [original], estimatedTokens: 12)],
                skippedAllocationIDs: [],
                inputBudget: 100,
                estimatedInputTokens: 12
            )
            try Expect.equal(frame.messages, [original], "Frame retains Message objects rather than flattening to text")
            try Expect.equal(try JSONDecoder().decode(Context.Frame.self, from: JSONEncoder().encode(frame)), frame, "Frame is round-trippable for inspection")
        }

        Test("derived-facts-keep-original-references") {
            let original = Context.Pointer(source: "run/A", record: "tool-result/4", revision: .recorded("revision-1"))
            let fact = Context.Record(id: "fact-1", kind: "fact", pointer: .init(source: "facts", record: "fact-1"), derivedFrom: [original])
            try Expect.equal(fact.derivedFrom, [original], "Derived records retain direct evidence provenance")
        }
    }
}
