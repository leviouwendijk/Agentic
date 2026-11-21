import Agentic
import AgenticStandard
import Primitives
import Testing

extension ExecutionTesting {
    static func runSearchResults()
        async throws
        -> [TestDiagnostic]
    {
        let error = "error: cannot find 'Widget' in scope"
        func response(
            _ id: String,
            _ tool: String,
            output: JSONValue,
            isError: Bool = false,
            text: String? = nil
        ) -> FunctionCall.Response {
            .init(call: .init(id: id, name: tool), output: output, isError: isError, text: text)
        }
        // Newest first, as the archive returns them.
        let responses = [
            response("c5", "read_result", output: .object(["text": .string("\(error)\nmore")])),
            response("c4", "list_items", output: .object(["items": .array([
                .object(["name": .string("alpha"), "size": .int(3)]),
                .object(["name": .string("beta"), "size": .int(5)]),
            ])])),
            response("c3", "count", output: .object(["count": .int(2)])),
            response(
                "c2",
                "swift_build",
                output: .object(["stdout": .string("Compiling B\n\(error)\nBuild failed"), "exitCode": .int(1)]),
                isError: true,
                text: "✗ build failed\n\(error)"
            ),
            response(
                "c1",
                "swift_build",
                output: .object(["stdout": .string("Compiling A\n\(error)\nBuild failed"), "exitCode": .int(1)]),
                isError: true
            ),
        ]
        let archive = ResultArchive(
            { call in responses.first { $0.call.id == call } },
            recent: { limit in Array(responses.prefix(limit)) }
        )
        let context = ToolContext(services: try ToolServices().inserting(archive))
        let search = Standard.Tools.SearchResults()

        // Segments derived from the record.
        let build = RecordedOutput(responses[3])
        try Expect.equal(build.segments.map(\.name), ["stdout", "text"], "a multi-line field and the rendering")
        try Expect.equal(build.segment(named: "stdout")?.elements.count, 3, "one element per stdout line")
        let list = RecordedOutput(responses[1])
        try Expect.equal(list.segment(named: "items")?.kind, .records, "an array of objects is records")
        try Expect.equal(list.segment(named: "items")?.elements.last?.fields["name"], "beta", "a record keeps its fields")
        let count = RecordedOutput(responses[2])
        try Expect.equal(count.segments.map(\.name), ["output"], "nothing derived: the record as JSON lines")

        // A literal query across results, newest first; the rendering's copy
        // of a stdout line is left out; read_result is not searched.
        let found = try await search.call(.init(query: "cannot find"), in: context)
        try Expect.equal(found.hits.map(\.call), ["c2", "c1"], "both builds, newest first, once each")
        try Expect.equal(found.hits.map(\.segment), ["stdout", "stdout"], "the record's segment wins over the rendering")
        try Expect.equal(found.searched, 4, "read_result's own results are not searched")

        // unique: one hit per text, counted.
        let unique = try await search.call(.init(query: "cannot find", unique: true), in: context)
        try Expect.equal(unique.hits.count, 1, "one hit for the repeated error")
        try Expect.equal(unique.hits.first?.occurrences, 2, "counted across results")

        // Context lines from the same segment.
        let around = try await search.call(.init(query: "cannot find", calls: ["c1"], contextLines: 1), in: context)
        try Expect.equal(around.hits.first?.before, ["Compiling A"], "the line before")
        try Expect.equal(around.hits.first?.after, ["Build failed"], "the line after")

        // Records, narrowed by tool; a regex pattern.
        let records = try await search.call(.init(query: "beta", tools: ["list_items"]), in: context)
        try Expect.equal(records.hits.map(\.segment), ["items"], "a record hit")
        try Expect.equal(records.hits.first?.line, 2, "the record's position")
        let pattern = try await search.call(.init(pattern: "^Build failed$", failed: true), in: context)
        try Expect.equal(pattern.hits.map(\.call), ["c2", "c1"], "a regex over failed results")

        // The rendering names where to read around a hit.
        let rendered = search.render(found, input: .init(query: "cannot find")) ?? ""
        try Expect.contains(rendered, "c2 swift_build · stdout", "grouped by result and segment")
        try Expect.contains(rendered, "\"segment\": \"stdout\"", "points read_result at the segment")

        // read_result pages a segment of the full output.
        let reader = Standard.Tools.ReadResult()
        let page = try await reader.call(.init(call: "c1", segment: "stdout", offset: 2, limit: 1), in: context)
        try Expect.equal(page.text, error, "one line of stdout")
        try Expect.equal(page.total, 3, "stdout's line count")
        var available: [String] = []
        do {
            _ = try await reader.call(.init(call: "c1", segment: "stderr"), in: context)
        } catch ReadResultError.noSegment(_, let names) {
            available = names
        }
        try Expect.equal(available, ["stdout"], "a missing segment names the ones there are")

        var refused = false
        do {
            _ = try await search.call(.init(), in: context)
        } catch SearchResultsError.noTerms {
            refused = true
        }
        try Expect.true(refused, "a search without terms is refused")

        return [
            .field("hits", "\(found.hits.count)"),
            .field("searched", "\(found.searched)"),
        ]
    }
}
