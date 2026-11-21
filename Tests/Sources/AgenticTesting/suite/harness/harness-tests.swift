import Agentic
import AgenticHarness
import Foundation
import IO
import Testing

enum HarnessTestSuite {
    static let testSuite = TestSuite(
        "harness",
        title: "Agentic Harness tests"
    ) {
        Test(
            "harness-catalog"
        ) { _ in
            let identifiers = Set(
                Harness.catalog.tools.map(
                    \.identifier
                )
            )

            try Expect.equal(
                identifiers.contains(
                    Harness.Tools.InspectInstallation.identifier
                ),
                true,
                "Harness catalog contains harness_tool_inspect_installation"
            )
            try Expect.equal(
                identifiers.contains(
                    Harness.Tools.InspectExposure.identifier
                ),
                true,
                "Harness catalog contains harness_tool_inspect_exposure"
            )
        }

        Test(
            "inspect-installation-source"
        ) { _ in
            let tool = Harness.Tools.InspectInstallation(
                source: HarnessInstallationInspectionSource()
            )
            let output = try await tool.call(
                .init(
                    kinds: [
                        "tool",
                    ],
                    identifier: "fixture.tool"
                ),
                in: ToolContext()
            )

            try Expect.equal(
                output.totalCount,
                2,
                "installation source controls total installation count"
            )
            try Expect.equal(
                output.returnedCount,
                1,
                "installation source can return a filtered projection"
            )
            try Expect.equal(
                output.entries.first?.identifier,
                "fixture.tool",
                "installation inspection forwards the requested identifier"
            )
            try Expect.equal(
                output.entries.first?.executable,
                true,
                "installation inspection distinguishes executable bindings"
            )
        }

        Test(
            "inspect-exposure-source"
        ) { _ in
            let tool = Harness.Tools.InspectExposure(
                source: HarnessExposureInspectionSource()
            )
            let output = try await tool.call(
                .init(
                    includeHidden: true
                ),
                in: ToolContext()
            )

            try Expect.equal(
                output.selectedCount,
                2,
                "exposure inspection reports the selected capability count"
            )
            try Expect.equal(
                output.exposedCount,
                1,
                "exposure inspection reports exposed capabilities"
            )
            try Expect.equal(
                output.hiddenCount,
                1,
                "exposure inspection reports hidden capabilities"
            )
            try Expect.equal(
                output.entries.count,
                2,
                "includeHidden is forwarded to the source"
            )
        }

        Test(
            "findings-record-extend-list"
        ) { _ in
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("harness-findings-\(UUID().uuidString)", isDirectory: true)
            defer { try? FileSystem.default.remove(directory) }
            let store = Harness.Improvements(directory: directory)
            let context = ToolContext(services: try ToolServices().inserting(store))

            do {
                _ = try await Harness.Tools.RecordFinding().call(
                    .init(category: .context, title: "x", detail: "x", evidence: [" "], proposal: "x"),
                    in: context
                )
                throw HarnessFindingTestFailure.recordedWithoutEvidence
            } catch HarnessFindingError.noEvidence {}

            let recorded = try await Harness.Tools.RecordFinding().call(
                .init(
                    category: .context,
                    title: "Shortened results are read again",
                    detail: "3 of 4 shortened results were read back with standard_tool_read_result within two turns.",
                    evidence: ["s1 step 12", "s1 step 19"],
                    effect: "≈2.1k input tokens per session",
                    proposal: "Raise the result budget for read_files to 1.5k tokens."
                ),
                in: context
            )
            try Expect.true(
                recorded.file.hasSuffix("-shortened-results-are-read-again.frame") && !recorded.extended,
                "a new finding gets a dated file named after its claim: \(recorded.file)"
            )
            let source = try Harness.Improvements.source(try store.finding(recorded.file))
            try Expect.true(
                source.hasPrefix("import Improvements;") && source.contains("let finding: Finding = "),
                "it is a Frame file of one Finding: \(source)"
            )

            let extended = try await Harness.Tools.RecordFinding().call(
                .init(
                    category: .context, title: "same", detail: "same",
                    evidence: ["s1 step 19", "s2 step 4"], proposal: "same",
                    extends: recorded.file
                ),
                in: context
            )
            try Expect.equal(extended.evidence, 3, "extending adds only new evidence")
            let finding = try store.finding(recorded.file)
            try Expect.equal(finding.title, "Shortened results are read again", "and keeps the claim")
            try Expect.equal(finding.status, .open, "and its status")

            let listed = try await Harness.Tools.ListFindings().call(.init(), in: context)
            try Expect.equal(listed.entries.map(\.file), [recorded.file], "the list names every finding")
            try Expect.equal(
                try await Harness.Tools.ListFindings().call(.init(category: .routing), in: context).entries.count,
                0,
                "and filters by category"
            )
            let noted = try await Harness.Tools.NoteFriction().call(
                .init(kind: .missing_capability, note: "no tool to read a PDF"),
                in: context
            )
            try Expect.true(noted.noted, "a friction note is acknowledged and changes nothing")
        }
    }
}

private enum HarnessFindingTestFailure: Error {
    case recordedWithoutEvidence
}

private struct HarnessInstallationInspectionSource:
    Harness.Tools.InspectInstallation.InspectionSource
{
    func inspect(
        _ input: Harness.Tools.InspectInstallation.Input
    ) async throws
        -> Harness.Tools.InspectInstallation.Output
    {
        .init(
            totalCount: 2,
            returnedCount: 1,
            entries: [
                .init(
                    kind: input.kinds.first ?? "tool",
                    identifier: input.identifier ?? "fixture.tool",
                    namespace: "fixture",
                    executable: true,
                    modelFacing: true
                ),
            ]
        )
    }
}

private struct HarnessExposureInspectionSource:
    Harness.Tools.InspectExposure.InspectionSource
{
    func inspect(
        _ input: Harness.Tools.InspectExposure.Input
    ) async throws
        -> Harness.Tools.InspectExposure.Output
    {
        var entries: [Harness.Tools.InspectExposure.Entry] = [
            .init(
                kind: "tool",
                identifier: "fixture.visible",
                state: "exposed"
            ),
        ]

        if input.includeHidden {
            entries.append(
                .init(
                    kind: "tool",
                    identifier: "fixture.hidden",
                    state: "hidden"
                )
            )
        }

        return .init(
            selectedCount: 2,
            exposedCount: 1,
            hiddenCount: 1,
            entries: entries
        )
    }
}
