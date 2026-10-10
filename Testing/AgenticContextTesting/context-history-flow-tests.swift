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
            history: .init(maximumTurns: 2, maximumTokens: 2_000))
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
            ["sys", "second", "third"], "Two-turn dynamic tail")
        try Expect.equal(noEvidence.history.omitted.map(\.messageID), ["first"],
            "Excluded material remains addressed")
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
}
