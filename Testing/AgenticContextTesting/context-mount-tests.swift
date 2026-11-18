import Agentic
import AgenticContext
import Foundation
import Testing

/// Shared context through mount files: entries under the mount's folder,
/// reads and saves through it, read-only mounts, and what is refused.
extension ContextFilesTests {
    static let sharedPeople = """
        import Context;

        let sam: Entry = .{
            .title = "Sam",
            .summary = "Co-owner; runs the workshops.",
            .tags = ["team"],
            .related = ["team.people.alex"],
            .body = "Sam runs the workshops.",
        };

        let alex: Entry = .{
            .title = "Alex",
            .summary = "Co-owner; home visits.",
            .tags = ["team"],
            .body = "Alex does the intake visits.",
        };
        """

    static func mountFile(_ path: String, readOnly: Bool = false) -> String {
        "import Context;\nlet shared: Mount = .{ .path = \"\(path)\", .readOnly = \(readOnly) };\n"
    }

    static func mounts() async throws {
        let (context, store, root) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        let shared = root.appendingPathComponent("shared", isDirectory: true)
        try FileManager.default.createDirectory(at: shared, withIntermediateDirectories: true)
        try sharedPeople.write(to: shared.appendingPathComponent("people.frame"), atomically: true, encoding: .utf8)
        _ = try store.save(person.replacingOccurrences(of: "business.services", with: "team.people.alex"), to: "mine.frame")

        // Checking a mount file before saving it shows what it brings in.
        let check = try await Context.Tools.Check().call(.init(file: "team.frame", text: mountFile(shared.path)), in: context)
        try Expect.equal(check.problems, [], "a mount checks: \(check.problems)")
        try Expect.equal(check.entries, [], "a mount file defines no entries itself")
        _ = try await Context.Tools.Save().call(.init(file: "team.frame", text: mountFile(shared.path)), in: context)

        let library = store.library()
        try Expect.equal(library.problems, [], "all hold: \(library.problems)")
        try Expect.equal(library.items.map(\.id).sorted(), ["mine.role", "team.people.alex", "team.people.sam"], "mounted entries under the mount's name")
        try Expect.equal(library.item("team.people.sam")?.file, "team/people.frame", "files read through the mount's folder")
        try Expect.true(library.groups.contains { $0.prefix == "team" && $0.entries == 2 }, "the mount is a group")
        try Expect.true(library.instructions?.contains("team (2)") == true, "and every agent hears of it")

        let file = try await Context.Tools.File().call(.init(file: "team/people.frame"), in: context)
        try Expect.equal(file.text, sharedPeople, "a mounted file reads through the mount")
        try Expect.equal(file.file, shared.appendingPathComponent("people.frame").standardizedFileURL.path, "from the shared directory")

        let changed = sharedPeople.replacingOccurrences(of: "runs the workshops.\",", with: "runs workshops and follow-ups.\",")
        let saved = try await Context.Tools.Save().call(.init(file: "team/people.frame", text: changed), in: context)
        try Expect.true(saved.saved, "a mounted file saves: \(saved.problems)")
        try Expect.equal(try String(contentsOf: shared.appendingPathComponent("people.frame"), encoding: .utf8), changed, "into the shared directory")
        try Expect.true(saved.archived?.hasPrefix(root.appendingPathComponent("archive").path) == true, "archived in this home: \(saved.archived ?? "-")")

        let added = try await Context.Tools.Save().call(.init(file: "team/clients/acme.frame", text: """
            import Context;
            let overview: Entry = .{ .title = "Acme", .summary = "A client.", .body = "Acme." };
            """), in: context)
        try Expect.true(added.saved && FileManager.default.fileExists(atPath: shared.appendingPathComponent("clients/acme.frame").path), "new files go into the shared directory")
        try Expect.true(store.library().item("team.clients.acme.overview") != nil, "and read back under the mount")

        // Read-only: neither checks nor saves.
        _ = try store.save(mountFile(shared.path, readOnly: true), to: "team.frame")
        let refused = try await Context.Tools.Save().call(.init(file: "team/people.frame", text: sharedPeople), in: context)
        try Expect.false(refused.saved, "a read-only mount is never written")
        try Expect.true(refused.problems.contains { $0.contains("read-only") }, "and says why: \(refused.problems)")
        try Expect.equal(try String(contentsOf: shared.appendingPathComponent("people.frame"), encoding: .utf8), changed, "the shared file is untouched")

        // What is refused.
        let missing = try await Context.Tools.Check().call(.init(file: "gone.frame", text: mountFile(root.appendingPathComponent("nowhere").path)), in: context)
        try Expect.true(missing.problems.contains { $0.contains("not a directory") }, "a mount to nothing: \(missing.problems)")
        let inside = try await Context.Tools.Check().call(.init(file: "loop.frame", text: mountFile(".")), in: context)
        try Expect.true(inside.problems.contains { $0.contains("inside this context directory") }, "a mount into context/ itself: \(inside.problems)")
        let mixed = mountFile(shared.path) + "let x: Entry = .{ .title = \"x\", .summary = \"x\", .body = \"x\" };\n"
        let crowded = try await Context.Tools.Check().call(.init(file: "crowded.frame", text: mixed), in: context)
        try Expect.true(crowded.problems.contains { $0.contains("nothing else") }, "a mount file holds only the mount: \(crowded.problems)")
        let nested = try await Context.Tools.Check().call(.init(file: "team/deeper.frame", text: mountFile(shared.path)), in: context)
        try Expect.false(nested.valid, "no mount inside a mount")

        try mountFile(root.path).write(to: shared.appendingPathComponent("inner.frame"), atomically: true, encoding: .utf8)
        try Expect.true(store.library().problems.contains { $0.hasPrefix("team/inner.frame:") && $0.contains("not followed") }, "a mount found inside a mounted directory is reported, not followed")
        try FileManager.default.removeItem(at: shared.appendingPathComponent("inner.frame"))

        // A real local folder of the mount's name is refused.
        try FileManager.default.createDirectory(at: store.directory.appendingPathComponent("team"), withIntermediateDirectories: true)
        try person.replacingOccurrences(of: "business.services", with: "team.people.alex")
            .write(to: store.directory.appendingPathComponent("team/clash.frame"), atomically: true, encoding: .utf8)
        try Expect.true(store.library().problems.contains { $0.contains("also a folder here") }, "a mount and a folder of one name: \(store.library().problems)")
    }
}
