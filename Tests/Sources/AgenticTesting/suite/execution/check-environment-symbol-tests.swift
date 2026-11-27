import Agentic
import AgenticStandard
import Foundation
import IO
import Milieu
import Testing
import Writers

extension ExecutionTesting {
    static func runCheckEnvironmentSymbol()
        async throws
        -> [TestDiagnostic]
    {
        let home = ProcessInfo.processInfo.environment["HOME"] ?? ""
        let fixture = URL.temporaryDirectory
            .appending(path: "check-environment-symbol-\(UUID().uuidString).env")
        try FileWriter(fixture).write(
            """
            # fixture
            export HOME="\(home)"
            PATH=not-the-process-path
            CHECK_ENV_FIXTURE_TOKEN=
            """,
            options: .overwriteWithoutBackup
        )
        defer { try? FileSystem.default.remove(fixture) }

        let sources = EnvironmentSymbolSources([
            .init(label: "fixture", url: fixture),
            .init(label: "absent", url: fixture.appendingPathExtension("missing")),
        ])
        let output = try await Standard.Tools.CheckEnvironmentSymbol().call(
            .init(names: ["HOME", "PAHT", "CHECK_ENV_FIXTURE_TOKEN", "PATH"]),
            in: CapabilityContext(services: try CapabilityServices().inserting(sources))
        )
        let byName = Dictionary(uniqueKeysWithValues: output.entries.map { ($0.name, $0) })

        try Expect.equal(byName["HOME"]?.status, .set,
            "a set variable reports set")
        try Expect.equal(byName["HOME"]?.declarations.first?.line, 2,
            "a declaration reports its line")
        try Expect.equal(byName["HOME"]?.declarations.first?.matches_process, true,
            "an equal declared value matches the process")
        try Expect.equal(byName["PATH"]?.declarations.first?.matches_process, false,
            "a different declared value does not match")
        try Expect.equal(byName["PAHT"]?.status, .missing,
            "an unknown name reports missing")
        try Expect.equal(byName["PAHT"]?.suggestions.first, "PATH",
            "a transposition suggests the real name")
        try Expect.equal(byName["CHECK_ENV_FIXTURE_TOKEN"]?.declarations.first?.matches_process, nil,
            "a name absent from the process has no match verdict")
        try Expect.equal(byName["CHECK_ENV_FIXTURE_TOKEN"]?.declarations.first?.is_empty, true,
            "an empty declaration is reported empty")
        try Expect.equal(output.scanned_sources, ["fixture"],
            "readable sources are listed")
        try Expect.equal(output.unreadable_sources, ["absent"],
            "an unreadable source is reported, not fatal")

        let inspector = EnvironmentInspector(environment: [
            "HONDENMEESTERS_API_KEY": "secret",
            "MAIL_HOST": "secret",
            "KEY": "secret",
        ])
        try Expect.equal(inspector.suggestions(for: "API_KEY_HONDENMEESTERS"), ["HONDENMEESTERS_API_KEY"],
            "reordered segments match")
        try Expect.equal(inspector.suggestions(for: "mail_host"), ["MAIL_HOST"],
            "a case-only difference matches first")
        try Expect.equal(inspector.suggestions(for: "UNRELATED_NAME"), [],
            "distant names are never listed")

        let encoded = String(decoding: try JSONEncoder().encode(output), as: UTF8.self)
        try Expect.equal(encoded.contains("not-the-process-path"), false,
            "no declared value reaches the output")

        return []
    }
}
