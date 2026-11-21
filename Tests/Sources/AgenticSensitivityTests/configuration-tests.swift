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
        try Expect.true(configured.resolution.related("io_tool_read", "io_tool_mutate"), "tools of one domain are related")

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
        let kept = await vault.handle(for: "sam@example.com", kind: .contact, tier: .handle, detector: "t", reason: "t", score: 90, source: "mail_tool_read", session: "s1")
        let gone = await vault.handle(for: "alex@example.com", kind: .contact, tier: .handle, detector: "t", reason: "t", score: 90, source: "mail_tool_read", session: "s1")

        let session = home.layout.runtimeStorage.sessiondir(sessionID: "s1")
        try FileManager.default.createDirectory(at: session, withIntermediateDirectories: true)
        try "{\"text\":\"Mail \(kept.token)\"}\n".write(to: session.appendingPathComponent("log.jsonl"), atomically: true, encoding: .utf8)

        let first = Privacy.Configuration.load(home: home)
        let written = home.layout.domainfile(Privacy.Configuration.fileName)
        try Expect.isNil(first.problem, "a missing file is no problem")
        try Expect.equal(try String(contentsOf: written, encoding: .utf8), SensitivityFrame.template, "the first load writes the template")
        try Expect.equal(try Privacy.Configuration(source: SensitivityFrame.template).expiry, .unreferenced, "the template holds the defaults")

        // Also referenced, outside sessions: a transcript.
        let elsewhere = await vault.handle(for: "noor@example.com", kind: .contact, tier: .handle, detector: "t", reason: "t", score: 90, source: "mail_tool_read", session: "s1")
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
        let protected = await installed.protecting(.string("Mail sam@example.com"), from: ToolIdentifier("mail_tool_read"))
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

/// Pinned sessions: kept, refused for routine scrubs, sealed.
enum PinTests {
    static func home() throws -> (AgentHome, URL) {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("agentic-home-\(UUID().uuidString)", isDirectory: true)
        setenv("AGENTIC_HOME", root.path, 1)
        return (AgentHomeLocator().resolveHome(), root)
    }

    static func pinnedSessionsAreDeliberate() async throws {
        let (home, root) = try home()
        defer { try? FileManager.default.removeItem(at: root); unsetenv("AGENTIC_HOME") }
        let storage = home.layout.runtimeStorage
        let session = "PINNED-FIXTURE"
        let log = storage.sessiondir(sessionID: session).appendingPathComponent("log.jsonl")
        try FileManager.default.createDirectory(at: log.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "{\"text\":\"Mail sam@example.com\"}\n".write(to: log, atomically: true, encoding: .utf8)
        try storage.pinSession(session, SessionPin(reason: "cited by a fixture page"))
        try Expect.equal(storage.pinnedSessions(), [session], "the pin is found")

        let (context, installed) = try GuardTests.context()
        var refused: (any Error)?
        do {
            _ = try await Privacy.Tools.ScrubSession().call(.init(session: session, dry_run: false), in: context)
        } catch {
            refused = error
        }
        try Expect.true(refused?.localizedDescription.contains("pinned") == true, "a routine scrub of a pinned session is refused")

        let scrubbed = try await Privacy.Tools.ScrubSession().call(
            .init(session: session, dry_run: false, reason: "deletion request"),
            in: context
        )
        try Expect.true(scrubbed.deliberate, "deliberate with a reason")
        let text = try String(contentsOf: log, encoding: .utf8)
        try Expect.false(text.contains("sam@example.com"), "the value is gone from the record")
        let handle = try Expect.notNil(Sensitivity.Handle.occurrences(in: text).first?.handle, "a handle in its place")
        try Expect.isNil(await installed.vault.value(of: handle), "and the vault forgot it: a deletion leaves no way back")

        let tombstones = try String(contentsOf: log.deletingLastPathComponent().appendingPathComponent("tombstones.jsonl"), encoding: .utf8)
        try Expect.true(tombstones.contains("deletion request") && tombstones.contains("sha256:") && tombstones.contains("\"contact\":1"), "a tombstone: reason, previous digest, kinds: \(tombstones)")
        try Expect.false(tombstones.contains("example.com"), "never values")
        try Expect.equal(storage.pin(sessionID: session)?.reason, "cited by a fixture page", "the pin itself stays")
    }

    static func pinnedHandlesAreCollected() async throws {
        let (home, root) = try home()
        defer { try? FileManager.default.removeItem(at: root); unsetenv("AGENTIC_HOME") }
        let storage = home.layout.runtimeStorage
        for (session, id) in [("A", "0000000a"), ("B", "0000000b")] {
            let directory = storage.sessiondir(sessionID: session)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try "⟦contact:\(id)⟧".write(to: directory.appendingPathComponent("log.jsonl"), atomically: true, encoding: .utf8)
        }
        try storage.pinSession("A", SessionPin(reason: "fixture"))
        try Expect.equal(Privacy.References.pinned(in: storage), ["0000000a"], "only what pinned sessions reference")
        try storage.unpinSession("A")
        try Expect.equal(storage.pinnedSessions(), [], "unpinned")
    }

    static func sealAndUnseal() async throws {
        guard ProcessInfo.processInfo.environment["AGENTIC_SENSITIVITY_KEYCHAIN_TEST"] == "1" else { return }
        let (home, root) = try home()
        defer { try? FileManager.default.removeItem(at: root); unsetenv("AGENTIC_HOME") }
        let storage = home.layout.runtimeStorage
        let here = Sensitivity.Vault(lifetime: nil)
        let handle = await here.handle(for: "sam@example.com", kind: .contact, tier: .handle, detector: "t", reason: "t", score: 90, source: "mail_tool_read", session: "S")
        let directory = storage.sessiondir(sessionID: "S")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "Mail \(handle.token)".write(to: directory.appendingPathComponent("log.jsonl"), atomically: true, encoding: .utf8)

        try Expect.equal(try await Privacy.seal(session: "S", storage: storage, vault: here), 1, "one value sealed")
        let sealed = try String(contentsOf: directory.appendingPathComponent("vault.sealed"), encoding: .utf8)
        try Expect.false(sealed.contains("sam@example.com"), "encrypted")

        let elsewhere = Sensitivity.Vault(lifetime: nil)
        try Expect.equal(try await Privacy.unseal(session: "S", storage: storage, vault: elsewhere), 1, "one value unsealed")
        try Expect.equal(await elsewhere.value(of: handle), "sam@example.com", "the handle resolves there")
    }
}
