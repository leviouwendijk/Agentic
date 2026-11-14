import Agentic
import AgenticContext
import Testing

extension ContextDeterministicFlowTesting {
    /// A rendered result is read by the model as its text; the structured
    /// output stays the record.
    static func runRenderedResults() throws -> [TestDiagnostic] {
        let call = FunctionCall(id: "c1", name: "scan_filepaths", input: .object([:]))
        let plain = FunctionCall.Response(
            call: call.reference,
            output: .object(["entries": .array([.string("Sources/a.swift")])])
        )
        let rendered = plain.rendered("Sources/\n    a.swift")

        try Expect.equal(
            plain.modelText,
            #"{"entries":["Sources/a.swift"]}"#,
            "Without a rendering the model reads compact JSON with unescaped paths"
        )
        try Expect.equal(rendered.modelText, "Sources/\n    a.swift", "A rendering is read as-is")
        try Expect.equal(rendered.output, plain.output, "The record keeps the structured output")

        let message = Message(id: "t", role: .tool, content: .init(blocks: [.result(rendered)]))
        guard case .result(let facing)? = message.modelFacing.content.blocks.first else {
            throw RenderedResultFixtureError.missingResult
        }
        try Expect.equal(
            facing.output,
            FunctionCall.Response(call: call.reference, output: .string("Sources/\n    a.swift")).output,
            "Measuring uses what the model reads"
        )

        // Results the model reads identically point at the first, even when
        // their records differ.
        let listing = (1...40).map { "entry-\($0).html" }.joined(separator: "\n")
        func exchange(_ id: String, count: Int) -> [Message] {
            let call = FunctionCall(id: id, name: "scan_filepaths", input: .object([:]))
            let response = FunctionCall.Response(call: call.reference, output: .object(["n": .int(count)]))
            return [
                .init(id: "a.\(id)", role: .assistant, content: .init(blocks: [.call(call)])),
                .init(id: "t.\(id)", role: .tool, content: .init(blocks: [
                    .result(response.rendered(listing)),
                ])),
            ]
        }
        let messages: [Message] =
            [.init(id: "u0", role: .user, content: .init(text: "Look around."))]
            + exchange("first", count: 1)
            + exchange("again", count: 2)
        let prepared = try Context.InferencePreparer.prepare(
            request: AgentRequest(messages: messages),
            frame: .init(workingSetID: "rendered", items: [], skippedAllocationIDs: [],
                         inputBudget: 0, estimatedInputTokens: 0),
            delivery: .dynamic,
            maximumInputTokens: 100_000,
            historyPolicy: .init(maximumTurns: 4, maximumTokens: 50_000)
        )
        guard let again = prepared.request.messages.first(where: { $0.id == "t.again" }),
              case .result(let pointed)? = again.content.blocks.first else {
            throw RenderedResultFixtureError.missingResult
        }
        try Expect.true(
            pointed.modelText.hasPrefix("[Unchanged: identical to the result of call first"),
            "A pointer is read as plain text"
        )

        let long = String(repeating: "x", count: 2_500)
        try Expect.equal(
            ResultLines.lines(of: "a\n" + long).map(\.count),
            [1, 1_000, 1_000, 500],
            "Long lines split so every part stays small"
        )
        return []
    }
}

private enum RenderedResultFixtureError: Error { case missingResult }
