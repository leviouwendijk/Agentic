import Agentic
import AgenticConfiguration
import AgenticSensitivity
import Foundation
import Primitives
import Sensitivity
import Testing

/// domains/sensitivity.frame and the vault lifecycle it sets.
enum ConfigurationTests {
    static func defaultsAndFile() throws {
        let standard = Privacy.Configuration.standard
        try Expect.equal(standard.store, .keychain, "a Keychain vault by default")
        try Expect.equal(standard.expiry, .unreferenced, "kept while a record holds the handle, by default")

        let configured = try Privacy.Configuration(source: """
            import Sensitivity;

            let vault: Vault = .{
                .store = .memory,
                .expire = .afterDays,
                .days = 14,
                .references = .sessions,
                .roots = ["~/provenance"],
            };

            let policy: Policy = .{
                .handleAt = 85,
                .softAt = 65,
                .never = ["Info@Example.com"],
                .families = [["notes_read", "drafts_write"]],
            };
            """)
        try Expect.equal(configured.store, .memory, "store")
        try Expect.equal(configured.expiry, .after(days: 14), "fourteen days")
        try Expect.equal(configured.references, .sessions, "references")
        try Expect.equal(configured.roots.first?.path, (("~/provenance" as NSString).expandingTildeInPath), "roots, ~ expanded")
        try Expect.equal(standard.references, .history, "anything in history, by default")
        try Expect.equal(configured.shield.handleAt, 85, "handle threshold")
        try Expect.equal(configured.shield.softAt, 65, "soft threshold")
        try Expect.true(configured.shield.never.contains("info@example.com"), "never, ignoring case")
        try Expect.true(configured.resolution.related("notes_read", "drafts_write"), "a declared family")
        try Expect.true(configured.resolution.related("read_files", "mutate_files"), "the standard family stays")

        let example = try Privacy.Configuration(source: SensitivityFrame.example)
        try Expect.equal(example.expiry, .unreferenced, "the example holds and keeps the defaults")

        try Expect.throwsError("afterDays needs days") {
            _ = try Privacy.Configuration(source: "import Sensitivity;\nlet vault: Vault = .{ .expire = .afterDays };")
        }
        try Expect.throwsError("softAt below handleAt") {
            _ = try Privacy.Configuration(source: "import Sensitivity;\nlet policy: Policy = .{ .handleAt = 60, .softAt = 70 };")
        }
    }

    static func unreferencedValuesAreSwept() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("agentic-home-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        setenv("AGENTIC_HOME", root.path, 1)
        defer { unsetenv("AGENTIC_HOME") }
        let home = AgentHomeLocator().resolveHome()

        let vault = Sensitivity.Vault(lifetime: nil)
        let kept = await vault.handle(for: "sam@example.com", kind: .contact, tier: .handle, detector: "t", reason: "t", score: 90, source: "mail_read", session: "s1")
        let gone = await vault.handle(for: "alex@example.com", kind: .contact, tier: .handle, detector: "t", reason: "t", score: 90, source: "mail_read", session: "s1")

        let session = home.layout.runtimeStorage.sessiondir(sessionID: "s1")
        try FileManager.default.createDirectory(at: session, withIntermediateDirectories: true)
        try "{\"text\":\"Mail \(kept.token)\"}\n".write(to: session.appendingPathComponent("log.jsonl"), atomically: true, encoding: .utf8)

        let first = Privacy.Configuration.load(home: home)
        let written = home.layout.domainfile(Privacy.Configuration.fileName)
        try Expect.isNil(first.problem, "a missing file is no problem")
        try Expect.equal(try String(contentsOf: written, encoding: .utf8), SensitivityFrame.template, "the first load writes the template")
        try Expect.equal(try Privacy.Configuration(source: SensitivityFrame.template).expiry, .unreferenced, "the template holds the defaults")

        // Also referenced, outside sessions: a transcript.
        let elsewhere = await vault.handle(for: "noor@example.com", kind: .contact, tier: .handle, detector: "t", reason: "t", score: 90, source: "mail_read", session: "s1")
        try FileManager.default.createDirectory(at: home.layout.runtimeStorage.transcriptsdir, withIntermediateDirectories: true)
        try "Reply to \(elsewhere.token)".write(to: home.layout.runtimeStorage.transcriptsdir.appendingPathComponent("t.md"), atomically: true, encoding: .utf8)

        let sessionsOnly = Privacy.Configuration(references: .sessions)
        try Expect.equal(
            sessionsOnly.historyRoots(in: home).reduce(into: Set<String>()) { $0.formUnion(Privacy.References.collect(below: $1)) },
            [kept.id],
            ".sessions: only what recorded sessions hold"
        )
        let history = Privacy.Configuration.standard
        let referenced = history.historyRoots(in: home).reduce(into: Set<String>()) { $0.formUnion(Privacy.References.collect(below: $1)) }
        try Expect.equal(referenced, [kept.id, elsewhere.id], ".history (the default): anything in the home")
        await vault.retain(referenced: referenced, now: Date().addingTimeInterval(2 * 60 * 60))
        try Expect.notNil(await vault.value(of: kept), "kept while recorded")
        try Expect.notNil(await vault.value(of: elsewhere), "kept while a transcript holds it")
        try Expect.isNil(await vault.value(of: gone), "dropped once no record holds it")
    }

    static func sessionCloseReleases() async throws {
        let configuration = Privacy.Configuration(store: .memory, expiry: .onSessionClose)
        var setup: (guarding: ToolPayloadGuarding, lease: Privacy.SessionLease?, problem: String?)? = Privacy.session("close-fixture", configuration: configuration)
        let installed = try Expect.notNil(setup?.guarding.shield as? Privacy.Guard, "the privacy guard")
        let protected = await installed.protecting(.string("Mail sam@example.com"), from: ToolIdentifier("mail_read"))
        let handle = try Expect.notNil(Sensitivity.Handle.occurrences(in: protected.stringValue ?? "").first?.handle, "a handle")
        try Expect.notNil(await installed.vault.value(of: handle), "held while the session runs")

        setup = nil
        for _ in 0..<50 where await installed.vault.value(of: handle) != nil {
            try await Task.sleep(for: .milliseconds(10))
        }
        try Expect.isNil(await installed.vault.value(of: handle), "released when the session's lease goes")
    }
}

private extension JSONValue {
    var stringValue: String? {
        if case .string(let text) = self { return text }
        return nil
    }
}
