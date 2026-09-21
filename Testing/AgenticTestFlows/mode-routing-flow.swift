import Agentic
import Foundation
import TestFlows

extension AgenticFlowTesting {
    static func runModeCatalogRegistersDefaultModes() async throws -> [TestFlowDiagnostic] {
        let catalog = try ModeCatalog.standard
        let modes = catalog.all
        let ids = modes.map(\.id)
        let expected: [AgenticModeIdentifier] = [
            .planning,
            .research,
            .coder,
            .review,
            .debugging,
            .cheap_utility,
            .private
        ]

        for id in expected {
            try Expect.true(
                ids.contains(id),
                "default mode \(id.rawValue)"
            )
        }

        return [
            .field(
                "modes",
                ids.map(\.rawValue).sorted().joined(separator: ",")
            )
        ]
    }

    static func runModePlanningSelectsPlannerPurpose() async throws -> [TestFlowDiagnostic] {
        let selection = try ModeCatalog.standard.selection(
            .planning
        )

        try Expect.equal(
            selection.routePolicy.purpose,
            .planner,
            "planning mode route purpose"
        )

        try Expect.equal(
            selection.configuration.autonomyMode,
            .suggest_only,
            "planning mode autonomy"
        )

        return [
            .field(
                "purpose",
                selection.routePolicy.purpose.rawValue
            ),
            .field(
                "autonomy",
                selection.configuration.autonomyMode.rawValue
            )
        ]
    }

    static func runModeResearchSelectsResearcherPurpose() async throws -> [TestFlowDiagnostic] {
        let selection = try ModeCatalog.standard.selection(
            .research
        )

        try Expect.equal(
            selection.routePolicy.purpose,
            .researcher,
            "research mode route purpose"
        )

        try Expect.equal(
            selection.routePolicy(
                for: .summarizer
            ).purpose,
            .summarizer,
            "research mode exposes summarizer route default"
        )

        return [
            .field(
                "purpose",
                selection.routePolicy.purpose.rawValue
            ),
            .field(
                "summarizer",
                selection.routePolicy(for: .summarizer).purpose.rawValue
            )
        ]
    }

    static func runModeCoderExposesFileMutationTools() async throws -> [TestFlowDiagnostic] {
        let selection = try ModeCatalog.standard.selection(
            .coder
        )

        try Expect.true(
            selection.exposedToolIdentifiers.contains(
                ReadFileTool.identifier
            ),
            "coder exposes read_file"
        )

        try Expect.true(
            selection.exposedToolIdentifiers.contains(
                ScanPathsTool.identifier
            ),
            "coder exposes scan_paths"
        )

        try Expect.true(
            selection.exposedToolIdentifiers.contains(
                MutateFilesTool.identifier
            ),
            "coder exposes mutate_files"
        )

        return [
            .field(
                "tools",
                selection.exposedToolIdentifiers.map(\.rawValue).joined(separator: ",")
            )
        ]
    }

    static func runModeReviewHidesMutationTools() async throws -> [TestFlowDiagnostic] {
        let selection = try ModeCatalog.standard.selection(
            .review
        )

        try Expect.equal(
            selection.exposedToolIdentifiers.contains(
                MutateFilesTool.identifier
            ),
            false,
            "review hides mutate_files"
        )

        return [
            .field(
                "tools",
                selection.exposedToolIdentifiers.map(\.rawValue).joined(separator: ",")
            )
        ]
    }

    static func runModePrivateRequiresLocalPrivatePolicy() async throws -> [TestFlowDiagnostic] {
        let selection = try ModeCatalog.standard.selection(
            .private
        )

        try Expect.equal(
            selection.routePolicy.purpose,
            .local_private,
            "private mode route purpose"
        )

        try Expect.equal(
            selection.routePolicy.privacy,
            .local_private,
            "private mode privacy"
        )

        try Expect.equal(
            selection.routePolicy.external,
            false,
            "private mode external access"
        )

        return [
            .field(
                "purpose",
                selection.routePolicy.purpose.rawValue
            ),
            .field(
                "privacy",
                selection.routePolicy.privacy.rawValue
            ),
            .field(
                "external",
                String(selection.routePolicy.external)
            )
        ]
    }

    static func runModeSelectionCodableRoundTrip() async throws -> [TestFlowDiagnostic] {
        let selection = try ModeCatalog.standard.selection(
            .coder
        )
        let data = try JSONEncoder().encode(
            selection
        )
        let decoded = try JSONDecoder().decode(
            ModeSelection.self,
            from: data
        )

        try Expect.equal(
            decoded.modeID,
            selection.modeID,
            "mode selection id round trip"
        )

        try Expect.equal(
            decoded.routePolicy.purpose,
            selection.routePolicy.purpose,
            "mode selection route purpose round trip"
        )

        try Expect.equal(
            decoded.exposedToolIdentifiers,
            selection.exposedToolIdentifiers,
            "mode selection tools round trip"
        )

        return [
            .field(
                "mode",
                decoded.modeID.rawValue
            ),
            .field(
                "purpose",
                decoded.routePolicy.purpose.rawValue
            ),
            .field(
                "tools",
                decoded.exposedToolIdentifiers.map(\.rawValue).joined(separator: ",")
            )
        ]
    }
}
