import Agentic
import AgenticContext
import Testing

private struct ContextHistoryResolver: Context.RecordResolving {
    func resolve(_ pointer: Context.Pointer) async throws -> Context.Resolved {
        .init(pointer: .init(source: pointer.source, record: pointer.record,
            selection: pointer.selection, revision: .recorded("fixture-v1")),
            messages: [.init(id: "retained.fact", role: .assistant,
                content: .init(text: "Use the corrected invocation shape."))])
    }
}

extension ContextDeterministicFlowTesting {
    static func runHistoryPolicies() async throws -> [TestDiagnostic] {
        let policy = Context.Policy(preferredInputTokens: 2_000,
            maximumInputTokens: 8_000, reservedOutputTokens: 500,
            history: .init(maximumTurns: 2, maximumTokens: 3_500))
        let allocator = try Context.Allocator(policy: policy)
        try await allocator.createWorkingSet(id: "history")
        let request = AgentRequest(messages: [
            .init(id: "sys", role: .system, content: .init(text: "Follow the task")),
            .init(id: "first", role: .user, content: .init(text: "Original instruction")),
            .init(id: "second", role: .user, content: .init(text: "Intermediate question")),
            .init(id: "third", role: .user, content: .init(text: "Current instruction")),
        ])
        let noEvidence = try await allocator.prepareDynamic(request: request,
            for: "history", using: ContextHistoryResolver(), modelContextLimit: 9_000)
        try Expect.equal(noEvidence.request.messages.map(\.id),
            ["sys", "first", "second", "third"], "Older turns stay while they fit")
        try Expect.equal(noEvidence.history.omitted.map(\.messageID), [],
            "Nothing is dropped within budget")
        let empty = Context.Frame(workingSetID: "history", items: [],
            skippedAllocationIDs: [], inputBudget: 8_000, estimatedInputTokens: 0)
        let accumulating = try Context.InferencePreparer.prepare(request: request,
            frame: empty, delivery: .supplement, maximumInputTokens: 8_000)
        try Expect.equal(accumulating.request.messages.map(\.id),
            ["sys", "first", "second", "third"], "Accumulating retains history")
        try await allocator.apply([.allocate(.init(id: "known-failure",
            pointer: .init(source: "fixture", record: "failure",
                revision: .recorded("fixture-v1")), required: true))], to: "history")
        let retained = try await allocator.prepareDynamic(request: request,
            for: "history", using: ContextHistoryResolver(), modelContextLimit: 9_000)
        try Expect.equal(retained.frame.items.map(\.allocationID), ["known-failure"],
            "Pinned finding is rehydrated")
        try Expect.equal(request.messages.count, 4, "Canonical request is untouched")
        let before = try await allocator.snapshot("history")
        let replay = try Context.Allocator(policy: policy)
        try await replay.restore(before, transitions: await allocator.recordedOperations(for: "history"))
        try Expect.equal(try await replay.snapshot("history"), before,
            "Transition replay matches original")
        return [.field("dynamic_messages", String(retained.request.messages.count)),
                .field("retained_items", String(retained.frame.items.count))]
    }

    static func runHistoryElision() throws -> [TestDiagnostic] {
        let bulky = String(repeating: "line of file content\n", count: 400)
        func exchange(_ id: String, output: String) -> [Message] {
            let call = FunctionCall(id: id, name: "read_file", input: .object(["path": .string(id)]))
            return [
                .init(id: "a.\(id)", role: .assistant, content: .init(blocks: [.call(call)])),
                .init(id: "t.\(id)", role: .tool, content: .init(blocks: [
                    .result(.init(call: call.reference, output: .string(output))),
                ])),
            ]
        }
        let messages: [Message] =
            [.init(id: "sys", role: .system, content: .init(text: "System"))]
            + [.init(id: "u0", role: .user, content: .init(text: "Read the sources."))]
            + exchange("old", output: "old\n" + bulky)
            + exchange("receipt", output: "wrote 3 lines")
            + [.init(id: "u1", role: .user, content: .init(text: "Correction: use the v2 API."))]
            + exchange("recent", output: "recent\n" + bulky)
            + [.init(id: "u2", role: .user, content: .init(text: "Now apply it."))]
            + exchange("fresh", output: "fresh\n" + bulky)
        let request = AgentRequest(messages: messages)
        let empty = Context.Frame(workingSetID: "elision", items: [],
            skippedAllocationIDs: [], inputBudget: 0, estimatedInputTokens: 0)

        // Two full-fidelity turns; the oldest turn's bulky read is elided.
        let roomy = try Context.InferencePreparer.prepare(request: request, frame: empty,
            delivery: .dynamic, maximumInputTokens: 100_000,
            historyPolicy: .init(maximumTurns: 2, maximumTokens: 50_000))
        try Expect.equal(roomy.request.messages.map(\.id), messages.map(\.id),
            "Within budget every message stays")
        try Expect.equal(roomy.history.elided.map(\.messageID), ["t.old"],
            "Bulky results leave with their turn's fidelity")
        guard case .result(let stub)? = roomy.request.messages[3].content.blocks.first,
              case .string(let text) = stub.output else {
            throw HistoryFixtureError.missingResult
        }
        try Expect.true(text.contains("call old"), "The stub names its call")
        try Expect.equal(roomy.request.messages[5], messages[5], "Small receipts are kept whole")

        // Tight budget: room for one bulky read, not two. Seen results go
        // first; the unseen fresh read stays.
        let tight = try Context.InferencePreparer.prepare(request: request, frame: empty,
            delivery: .dynamic, maximumInputTokens: 100_000,
            historyPolicy: .init(
                maximumTurns: 2,
                maximumTokens: roomy.measurement.estimatedInputTokens * 3 / 4
            ))
        try Expect.equal(tight.history.elided.map(\.messageID), ["t.old", "t.recent"],
            "Seen results are elided before anything is dropped")
        try Expect.true(tight.request.messages.contains(messages[11]),
            "The result the model has not seen yet stays whole")
        try Expect.true(tight.request.messages.contains(messages[6]),
            "User corrections are never elided")
        try Expect.equal(request.messages, messages, "The canonical request is untouched")

        return [.field("elided", String(tight.history.elided.count))]
    }
}

extension ContextDeterministicFlowTesting {
    static func runRepeatedResultPointers() throws -> [TestDiagnostic] {
        let listing = (1...40).map { "entry-\($0).html" }.joined(separator: "\n")
        func exchange(_ id: String, output: String) -> [Message] {
            let call = FunctionCall(id: id, name: "scan_filepaths", input: .object(["path": .string(".")]))
            return [
                .init(id: "a.\(id)", role: .assistant, content: .init(blocks: [.call(call)])),
                .init(id: "t.\(id)", role: .tool, content: .init(blocks: [
                    .result(.init(call: call.reference, output: .string(output))),
                ])),
            ]
        }
        let messages: [Message] =
            [.init(id: "u0", role: .user, content: .init(text: "Look around."))]
            + exchange("first", output: listing)
            + exchange("again", output: listing)
            + exchange("other", output: listing + "\nnew.html")
            + exchange("small", output: "ok")
            + exchange("small2", output: "ok")
        let prepared = try Context.InferencePreparer.prepare(
            request: AgentRequest(messages: messages),
            frame: .init(workingSetID: "pointers", items: [], skippedAllocationIDs: [],
                         inputBudget: 0, estimatedInputTokens: 0),
            delivery: .dynamic,
            maximumInputTokens: 100_000,
            historyPolicy: .init(maximumTurns: 4, maximumTokens: 50_000)
        )
        func output(_ id: String) -> String? {
            guard let message = prepared.request.messages.first(where: { $0.id == id }),
                  case .result(let response)? = message.content.blocks.first,
                  case .string(let text) = response.output else { return nil }
            return text
        }
        try Expect.equal(output("t.first"), listing, "The first result stays whole")
        try Expect.true(
            output("t.again")?.contains("call first") == true,
            "A repeated identical result points at the original"
        )
        try Expect.equal(output("t.other"), listing + "\nnew.html", "A changed result stays whole")
        try Expect.equal(output("t.small2"), "ok", "Small repeats are not worth a pointer")
        try Expect.equal(prepared.history.elided.map(\.messageID), ["t.again"], "The pointer is recorded")
        return []
    }
}

private enum HistoryFixtureError: Error { case missingResult }
