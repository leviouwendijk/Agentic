import Agentic
import Difference
import Foundation
import Schema

private enum PreflightTestFailure: Error {
    case failed(String)
}

enum AgenticPreflightTests {
    static func run() throws {
        let graph = GraphDifferenceLayout(
            nodes: [
                .init(
                    id: "lan",
                    change: .modified,
                    before: .init(label: "LAN"),
                    after: .init(label: "LAN updated")
                ),
                .init(
                    id: "wan",
                    change: .unchanged,
                    before: .init(label: "WAN"),
                    after: .init(label: "WAN")
                ),
            ],
            edges: [
                .init(
                    id: "policy",
                    change: .added,
                    before: nil,
                    after: .init(
                        endpoints: .init(source: "lan", destination: "wan"),
                        presentation: .init(label: "Policy")
                    )
                ),
            ]
        )

        let graphDifference = ToolPreflight.Preview.Difference(
            title: "Proposed network configuration",
            graph: graph
        )

        try check(graphDifference.layout.isEmpty, "graph-only preview needs no text lines")
        try check(!graphDifference.isEmpty, "graph-only difference must not be empty")
        try check(graphDifference.graph_layout == graph, "graph layout identity")
        try check(
            graphDifference.changeSummary == "graph: 1 changed of 2 nodes, 1 changed of 1 edges",
            "graph change summary"
        )
        try check(
            graphDifference.presentation.summary.graph?.nodes.changed == 1,
            "typed graph node count"
        )
        try check(
            graphDifference.presentation.summary.graph?.edges.changed == 1,
            "typed graph edge count"
        )

        let preview = ToolPreflight.Preview(difference: graphDifference)
        try check(!preview.isEmpty, "graph-only preflight preview")

        let preflight = ToolPreflight(
            tool: .init(rawValue: "graph_fixture"),
            risk: .boundedmutate,
            summary: "Inspect proposed changes",
            preview: preview
        )
        try check(
            preflight.description.contains("diff preview: graph: 1 changed of 2 nodes, 1 changed of 1 edges"),
            "description includes graph summary"
        )

        let inspection = preflight.inspectionDocument()
        let previewSection = inspection.sections.first { $0.title == "Preview" }
        let hasGraphSummary = previewSection?.items.contains { item in
            if case .field(let label, let value) = item {
                return label == "diff" && value.contains("graph: 1 changed")
            }
            return false
        } ?? false
        try check(hasGraphSummary, "inspection includes graph summary")

        let restoredPreflight = try JSONDecoder().decode(
            ToolPreflight.self,
            from: JSONEncoder().encode(preflight)
        )
        try check(restoredPreflight == preflight, "graph preflight Codable roundtrip")
        try check(
            restoredPreflight.preview.difference?.graph == graph,
            "graph data survives serialization"
        )

        let originalText = DifferenceLayout(lines: [
            .init(role: .insert, text: "new line"),
            .init(role: .delete, text: "old line"),
        ])
        let legacy = ToolPreflight.Preview.Difference(layout: originalText)
        try check(
            legacy.changeSummary == "1 insertions, 1 deletions",
            "legacy text summary remains unchanged"
        )
        try check(legacy.graph == nil, "legacy preview contains no graph")

        let legacyData = try JSONEncoder().encode(legacy)
        let legacyRestored = try JSONDecoder().decode(
            ToolPreflight.Preview.Difference.self,
            from: legacyData
        )
        try check(legacyRestored == legacy, "legacy decoding compatibility")
        try check(legacyRestored.graph == nil, "missing graph key decodes as nil")

        let tree = TreeDifferenceLayout(lines: [
            .init(
                depth: 0,
                is_last_child: true,
                ancestor_last: [],
                change: .modified,
                label: "Root",
                id: "root"
            ),
        ])
        let combined = ToolPreflight.Preview.Difference(
            layout: originalText,
            tree: tree,
            graph: graph
        )
        try check(
            combined.changeSummary.contains("1 insertions, 1 deletions"),
            "combined text summary"
        )
        try check(
            combined.changeSummary.contains("tree: 1 changed of 1 nodes"),
            "combined tree summary"
        )
        try check(
            combined.changeSummary.contains("graph: 1 changed of 2 nodes"),
            "combined graph summary"
        )

        let empty = ToolPreflight.Preview.Difference()
        try check(empty.isEmpty, "empty difference")
        try check(ToolPreflight.Preview(difference: empty).isEmpty, "empty preview")
        try check(empty.changeSummary == "no differences", "empty summary")

        let schemaData = try JSONEncoder().encode(
            ToolPreflight.Preview.Difference.jsonschema.jsonvalue
        )
        let schemaText = String(decoding: schemaData, as: UTF8.self)
        try check(schemaText.contains("\"graph\""), "preflight difference schema includes graph")

        print("PASS Agentic graph preflight: text, tree, graph, inspection, Codable, schema")
    }

    private static func check(
        _ condition: @autoclosure () -> Bool,
        _ message: String
    ) throws {
        guard condition() else {
            throw PreflightTestFailure.failed(message)
        }
    }
}
