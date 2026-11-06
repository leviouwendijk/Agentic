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
    static func main() throws {
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
        try CallTreeSmoke.run()
        try AgenticPreflightTests.run()
        try ToolServicesSmoke.run()
        print("AgenticStructures smoke: passed")
    }

    static func check(_ condition: @autoclosure () -> Bool, _ description: String) throws {
        guard condition() else { throw SmokeFailure.failed(description) }
    }
}
