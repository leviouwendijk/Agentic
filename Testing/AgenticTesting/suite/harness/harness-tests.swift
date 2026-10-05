import Agentic
import AgenticHarness
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
                "Harness catalog contains inspect_installation"
            )
            try Expect.equal(
                identifiers.contains(
                    Harness.Tools.InspectExposure.identifier
                ),
                true,
                "Harness catalog contains inspect_exposure"
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
    }
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

        if input.resolvedIncludeHidden {
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
