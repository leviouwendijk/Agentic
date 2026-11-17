import Agentic
import AgenticStandard
import Foundation
import Primitives
import Reporting
import Search

private enum SmokeFailure: Error {
    case failed(String)
    case expected_rejection
}

@main
struct AgenticStructuresSmoke {
    static func main() async throws {
        typealias GraphTool = Standard.Tools.CreateGraph
        let graphInput = GraphTool.Input(
            nodes: [
                .init(id: "root", value: .object(["label": .string("Root")])),
                .init(id: "left", value: .string("Left branch")),
                .init(id: "right", value: .string("Right branch")),
                .init(id: "merge", value: .string("Merge")),
            ],
            edges: [
                .init(id: "a", source: "root", destination: "left", value: .null),
                .init(id: "b", source: "root", destination: "right", value: .null),
                .init(id: "c", source: "left", destination: "merge", value: .string("parent")),
                .init(id: "d", source: "right", destination: "merge", value: .string("parent")),
            ],
            references: [
                .init(id: "main", target: "merge"),
                .init(id: "external", target: "not_in_snapshot"),
            ]
        )
        let graph = try GraphTool.evaluate(graphInput)
        try check(graph.graph.nodes.count == 4 && graph.graph.edges.count == 4, "validated graph")
        try check(graph.references.target(for: "main") == "merge", "reference identity")
        try check(graph.references.target(for: "external") == "not_in_snapshot", "off-graph reference")
        let graphRestored = try JSONDecoder().decode(GraphTool.Output.self, from: JSONEncoder().encode(graph))
        try check(graphRestored == graph, "typed graph JSON roundtrip")
        guard case .graph(let presented)? = GraphTool().present(graph, input: graphInput)?.document.blocks.first else {
            throw SmokeFailure.failed("graph presentation")
        }
        try check(presented.nodes.map(\.label) == ["Root", "Left branch", "Right branch", "Merge"], "legacy value labels presented")
        try check(presented.references.count == 2, "references presented")
        do {
            _ = try GraphTool.evaluate(.init(
                nodes: [.init(id: "a", value: .null)],
                edges: [.init(id: "bad", source: "a", destination: "missing", value: .null)]
            ))
            throw SmokeFailure.expected_rejection
        } catch GraphValidationError<String, String>.unknown_destination {}
        do {
            _ = try GraphTool.evaluate(.init(
                nodes: [.init(id: "a", value: .null)], edges: [],
                references: [.init(id: "same", target: "a"), .init(id: "same", target: "a")]
            ))
            throw SmokeFailure.expected_rejection
        } catch ReferenceSetError<String, String>.duplicate_reference {}

        typealias ReportTool = Standard.Tools.CreateReport
        let reportInput = ReportTool.Input(
            title: "Illustrative revenue",
            datasets: [.init(
                id: "months",
                columns: [
                    .init(name: "month", kind: .text),
                    .init(name: "revenue", kind: .decimal),
                    .init(name: "count", kind: .integer),
                ],
                rows: [
                    .init(values: [.string("January"), .string("123.45"), .int(2)]),
                    .init(values: [.string("February"), .string("-20.00"), .int(1)]),
                ]
            )],
            blocks: [
                .init(kind: .narrative, text: "Unverified example data"),
                .init(kind: .table, title: "Monthly", dataset: "months", columns: ["month", "revenue", "count"]),
                .init(kind: .bar, title: "Revenue", dataset: "months", x: "month", y: "revenue"),
            ]
        )
        let report = try ReportTool.evaluate(reportInput)
        try check(report.document.datasets[0].coverage == .unknown, "model-authored coverage remains unknown")
        try check(report.document.blocks.count == 3, "report has narrative, table, and chart")
        let reportRestored = try JSONDecoder().decode(ReportTool.Output.self, from: JSONEncoder().encode(report))
        try check(reportRestored == report, "typed report JSON roundtrip")
        do {
            _ = try ReportTool.evaluate(.init(
                title: "Invalid", datasets: [.init(
                    id: "bad",
                    columns: [.init(name: "amount", kind: .decimal)],
                    rows: [.init(values: [.double(0.1)])]
                )], blocks: []
            ))
            throw SmokeFailure.expected_rejection
        } catch ReportTool.Failure.invalid_value {}
        do {
            _ = try ReportTool.evaluate(.init(
                title: "Invalid chart", datasets: [.init(
                    id: "d",
                    columns: [.init(name: "word", kind: .text)],
                    rows: [.init(values: [.string("hello")])]
                )], blocks: [.init(kind: .line, dataset: "d", x: "word", y: "word")]
            ))
            throw SmokeFailure.expected_rejection
        } catch ReportDocument.Failure.invalidChartMeasure {}
        try await tracedReport()
        try CallTreeSmoke.run()
        try AgenticPreflightTests.run()
        try ToolServicesSmoke.run()
        print("AgenticStructures smoke: passed")
    }

    /// Datasets read from an earlier call are complete and traced to it;
    /// narrative is Markdown; facts and callouts are typed blocks.
    static func tracedReport() async throws {
        typealias ReportTool = Standard.Tools.CreateReport
        let slots: JSONValue = .object([
            "candidates": .array([
                .object(["start": .string("2026-11-18T10:00:00+01:00"), "score": .double(0.82),
                         "travel": .object(["minutes": .int(15)]), "optional_available": .array([.string("Anna")])]),
                .object(["start": .string("2026-11-18T14:00:00+01:00"), "score": .int(1),
                         "travel": .object(["minutes": .null]), "optional_available": .array([])]),
            ]),
        ])
        let archive = ResultArchive { call in
            call == "slots-1" ? .init(call: .init(id: call, name: "schedule_find_slots"), output: slots) : nil
        }
        let context = ToolContext(services: try ToolServices().inserting(archive))
        let input = ReportTool.Input(
            title: "Options",
            datasets: [.init(
                id: "slots",
                columns: [
                    .init(name: "start", kind: .date),
                    .init(name: "score", kind: .decimal),
                    .init(name: "travel", kind: .integer, field: "travel.minutes"),
                    .init(name: "optional_available", kind: .text),
                ],
                from_call: "slots-1",
                rows_path: "candidates"
            )],
            blocks: [
                .init(kind: .facts, facts: [.init(label: "Recommended", value: "Tue 10:00")]),
                .init(kind: .narrative, text: "Two options:\n\n- **morning**\n- afternoon"),
                .init(kind: .callout, title: "Gap", text: "No location", tone: .warning),
                .init(kind: .table, dataset: "slots", columns: ["start", "score", "travel"]),
            ]
        )
        let output = try await ReportTool().call(input, in: context)
        let dataset = output.document.datasets[0]
        try check(dataset.coverage == .complete, "call-backed dataset is complete")
        try check(dataset.rows.count == 2, "rows read from the call")
        try check(dataset.rows[0].sources == [.init(namespace: "tool_call", identifier: "slots-1#candidates.0")], "row traced to call")
        try check(dataset.rows[0].values[2] == .integer(15) && dataset.rows[1].values[2] == nil, "nested field path; null stays missing")
        try check(dataset.rows[0].values[3] == .text("Anna"), "string arrays join as text")
        guard case .narrative(.collection(let parts)) = output.document.blocks[1], parts.count == 2 else {
            throw SmokeFailure.failed("markdown narrative parsed into blocks")
        }
        guard case .callout(let callout) = output.document.blocks[2], callout.tone == .warning else {
            throw SmokeFailure.failed("callout block")
        }
        try check(ReportTool().render(output, input: input)?.contains("slots: 2 rows") == true, "model reads a summary")

        // A team's agenda: rows across participants, lane from the parent,
        // marks read from the tool's own words.
        let agenda: JSONValue = .object(["participants": .array([
            .object(["participant": .string("Levi"), "entries": .array([
                .object(["start": .string("2026-11-24T09:00:00+01:00"), "end": .string("2026-11-24T10:00:00+01:00"),
                         "title": .string("Standup"), "reading": .string("blocking")]),
                .object(["start": .string("2026-11-24T14:00:00+01:00"), "end": .string("2026-11-24T15:30:00+01:00"),
                         "title": .string("Office day"), "reading": .string("reserved")]),
                .object(["start": .string("2026-11-24T00:00:00+01:00"), "end": .string("2026-11-25T00:00:00+01:00"),
                         "title": .string("Holiday"), "reading": .string("marked_free")]),
            ])]),
            .object(["participant": .string("Anna"), "entries": .array([
                .object(["start": .string("2026-11-24T11:00:00+01:00"), "end": .string("2026-11-24T12:00:00+01:00"),
                         "title": .string("Open slot"), "reading": .string("offer")]),
            ])]),
        ])])
        let teamArchive = ResultArchive { call in
            call == "agenda-1" ? .init(call: .init(id: call, name: "schedule_agenda"), output: agenda) : nil
        }
        let week = try await ReportTool().call(.init(
            title: "Week",
            datasets: [.init(
                id: "entries",
                columns: [
                    .init(name: "who", kind: .text, field: "../participant"),
                    .init(name: "start", kind: .date), .init(name: "end", kind: .date),
                    .init(name: "title", kind: .text), .init(name: "reading", kind: .text),
                ],
                from_call: "agenda-1",
                rows_path: "participants.*.entries"
            )],
            blocks: [.init(kind: .timeline, dataset: "entries", start: "start", end: "end",
                           lane: "who", label: "title", mark: "reading", time_zone: "Europe/Amsterdam")]
        ), in: ToolContext(services: try ToolServices().inserting(teamArchive)))
        try check(week.document.datasets[0].rows.count == 4, "rows flattened across participants")
        try check(week.document.datasets[0].rows[3].sources[0].identifier == "agenda-1#participants.1.entries.0", "flattened rows keep their path")
        guard case .timeline(let timeline) = week.document.blocks[0] else {
            throw SmokeFailure.failed("timeline from rows")
        }
        try check(timeline.lanes.map(\.label) == ["Levi", "Anna"], "lanes from the parent, in order")
        try check(timeline.lanes[0].spans.map(\.mark) == [.occupied, .reserved], "tool words read as marks; unknown left off")
        try check(timeline.lanes[1].spans.first?.mark == .available && timeline.lanes[1].spans.first?.label == "Open slot", "offer is available")
        try check(timeline.timeZone == "Europe/Amsterdam", "axis zone")
        let window = ISO8601DateFormatter()
        try check(timeline.start == window.date(from: "2026-11-24T08:00:00Z"), "window from the first start, in whole hours")
        try check(timeline.end == window.date(from: "2026-11-24T15:00:00Z"), "window to the last end, in whole hours")
        do {
            _ = try ReportTool.evaluate(.init(title: "x", datasets: [], blocks: [.init(kind: .table, dataset: "d", columns: ["a"], start: "s")]))
            throw SmokeFailure.expected_rejection
        } catch ReportTool.Failure.invalid_block {}

        do {
            _ = try await ReportTool().call(.init(
                title: "Missing", datasets: [.init(id: "x", columns: [], from_call: "nope")], blocks: []
            ), in: context)
            throw SmokeFailure.expected_rejection
        } catch ReportTool.Failure.invalid_source {}
        do {
            _ = try await ReportTool().call(.init(
                title: "Path", datasets: [.init(id: "x", columns: [], from_call: "slots-1", rows_path: "nothing")], blocks: []
            ), in: context)
            throw SmokeFailure.expected_rejection
        } catch ReportTool.Failure.invalid_source {}

        // Models see tool names, not call identifiers: a tool name reads
        // its latest result, and `rows` may be left out entirely.
        let named = ResultArchive(
            { _ in nil },
            latest: { tool in tool == "schedule_agenda" ? .init(call: .init(id: "agenda-7", name: tool), output: agenda) : nil }
        )
        let decoded = try JSONDecoder().decode(ReportTool.Input.self, from: Data("""
            {"title": "Week", "datasets": [{"id": "e", "from_call": "schedule_agenda", "rows_path": "participants.*.entries",
              "columns": [{"name": "title", "kind": "text"}]}],
             "blocks": [{"kind": "table", "dataset": "e", "columns": ["title"]}]}
            """.utf8))
        let latest = try await ReportTool().call(decoded, in: ToolContext(services: try ToolServices().inserting(named)))
        try check(latest.document.datasets[0].rows.count == 4, "tool name reads its latest result")
        try check(latest.document.datasets[0].rows[0].sources[0].identifier.hasPrefix("agenda-7#"), "traced to the concrete call")

        // Errors say what the block needs.
        do {
            _ = try ReportTool.evaluate(.init(title: "x", datasets: [], blocks: [.init(kind: .callout, tone: .warning)]))
            throw SmokeFailure.expected_rejection
        } catch ReportTool.Failure.invalid_block(_, let reason) {
            try check(reason.contains("`text` and `tone` on the block itself"), "callout error explains the shape")
        }
    }

    static func check(_ condition: @autoclosure () -> Bool, _ description: String) throws {
        guard condition() else { throw SmokeFailure.failed(description) }
    }
}
