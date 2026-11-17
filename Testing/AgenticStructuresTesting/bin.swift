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
        guard case .graph(let presented)? = GraphTool().present(graph, input: graphInput)?.blocks.first else {
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
    }

    static func check(_ condition: @autoclosure () -> Bool, _ description: String) throws {
        guard condition() else { throw SmokeFailure.failed(description) }
    }
}
