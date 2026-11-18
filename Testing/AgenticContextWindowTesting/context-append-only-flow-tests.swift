import Agentic
import AgenticContextWindow
import Foundation
import Testing

extension ContextDeterministicFlowTesting {
    private static func appendOnly(
        _ request: AgentRequest,
        maximumInputTokens: Int = 100_000,
        compactions: [Context.Compaction] = []
    ) throws -> Context.InferencePreparation {
        try Context.InferencePreparer.prepare(
            request: request,
            frame: .init(
                workingSetID: "append-only", items: [], skippedAllocationIDs: [],
                inputBudget: 0, estimatedInputTokens: 0
            ),
            delivery: .dynamic,
            maximumInputTokens: maximumInputTokens,
            historyPolicy: .init(maximumTurns: 1, maximumTokens: 500),
            compactions: compactions
        )
    }

    private static func turn(_ id: String, result: String) -> [Message] {
        let call = FunctionCall(id: "call.\(id)", name: "read_file", input: .object([:]))
        return [
            .init(id: "user.\(id)", role: .user, content: .init(text: "Task \(id)")),
            .init(id: "assistant.call.\(id)", role: .assistant, content: .init(blocks: [.call(call)])),
            .init(id: "tool.\(id)", role: .tool, content: .init(blocks: [
                .result(.init(call: call.reference, output: .string(result))),
            ])),
            .init(id: "assistant.answer.\(id)", role: .assistant, content: .init(text: "Answer \(id)")),
        ]
    }

    /// Each request repeats the previous one's messages byte for byte and
    /// only adds to them, even far past the (fitted-mode) history budget.
    static func runAppendOnlyPrefix() throws {
        var request = AgentRequest(messages: [
            .init(id: "system", role: .system, content: .init(text: "Follow the task.")),
        ])
        var previous: [Message] = []
        for index in 0..<4 {
            request.messages += turn("\(index)", result: String(repeating: "line \(index)\n", count: 400))
            let prepared = try appendOnly(request).request.messages.map(\.modelFacing)
            try Expect.equal(
                Array(prepared.prefix(previous.count)), previous,
                "Request \(index) keeps every earlier message unchanged"
            )
            try Expect.equal(prepared.count, request.messages.count, "Nothing is dropped")
            previous = prepared
        }
    }

    /// Soft pressure only advises; past the hard limit, nothing is sent.
    static func runAppendOnlyPressure() throws {
        let request = AgentRequest(messages: turn("0", result: String(repeating: "source line\n", count: 600)))
        let full = try appendOnly(request)
        let estimate = full.measurement.estimatedInputTokens
        try Expect.equal(full.pressure?.level, .normal, "Far below the limit")

        let near = try appendOnly(request, maximumInputTokens: estimate * 3 / 2)
        try Expect.equal(near.pressure?.level, .soft, "Past 60% of the limit is soft pressure")
        try Expect.equal(near.request, full.request, "Soft pressure changes nothing")

        do {
            _ = try appendOnly(request, maximumInputTokens: estimate / 2)
            try Expect.true(false, "Past the limit the request is refused")
        } catch ContextInferenceError.inputBudgetExceeded {
        }
    }

    /// A compaction is a list of pointers to preserved results, applied to
    /// every later request the same way; the two newest turns stay whole.
    static func runCompaction() throws {
        func bulky(_ id: Int) -> String { String(repeating: "preserved source line \(id)\n", count: 300) }
        var request = AgentRequest(messages: turn("0", result: bulky(0)) + turn("1", result: bulky(1)) + turn("2", result: bulky(2)))
        guard let compaction = Context.Compactor.plan(messages: request.messages) else {
            try Expect.true(false, "An older bulky result can be compacted")
            return
        }
        try Expect.equal(compaction.pointers.map(\.call.id), ["call.0"], "Only turns before the previous one")
        try Expect.true(compaction.estimatedTokensSaved > 256, "It names what it saves")
        try Expect.true(
            Context.Compactor.plan(messages: request.messages, excluding: [compaction]) == nil,
            "A compacted result is not compacted twice"
        )

        let compacted = try appendOnly(request, compactions: [compaction])
        let tool = compacted.request.messages.first { $0.id == "tool.0" }
        guard case .result(let pointed)? = tool?.content.blocks.first else {
            try Expect.true(false, "The call keeps its result block")
            return
        }
        try Expect.true(
            pointed.modelText.contains("read_session_history(fromMessageID: \"tool.0\""),
            "The pointer says how to read the result back: \(pointed.modelText)"
        )
        try Expect.equal(compacted.history.changes?.map(\.reason), [.compacted], "The change is named")
        try Expect.true(
            compacted.request.messages.contains { $0.id == "tool.1" && $0.content == request.messages[6].content },
            "The previous turn stays whole"
        )

        request.messages += turn("3", result: "short")
        let later = try appendOnly(request, compactions: [compaction]).request.messages.map(\.modelFacing)
        let before = compacted.request.messages.map(\.modelFacing)
        try Expect.equal(Array(later.prefix(before.count)), before, "After compacting, the prefix is stable again")
    }
}
