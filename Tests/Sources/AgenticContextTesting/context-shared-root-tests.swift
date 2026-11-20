import Agentic
import AgenticContext
import Foundation
import Testing

/// Shared context through roots: a shared root's `.agentic/context` reads as
/// a folder named after the root, reads and saves go through it, a root not
/// declared writable refuses saves, and what clashes is reported.
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

    /// A store over `root/context` with `root/team/.agentic/context` as the shared root `team`.
    static func sharedFixture(readOnly: Bool = false) throws -> (ToolContext, Context.Store, URL, URL) {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("agentic-context-\(UUID().uuidString)", isDirectory: true)
        let shared = root.appendingPathComponent("team/.agentic/context", isDirectory: true)
        try FileManager.default.createDirectory(at: shared, withIntermediateDirectories: true)
        let store = Context.Store(
            directory: root.appendingPathComponent("context", isDirectory: true),
            archiveDirectory: root.appendingPathComponent("archive/context", isDirectory: true),
            shared: [.init(folder: "team", directory: shared, readOnly: readOnly)]
        )
        return (ToolContext(services: try ToolServices().inserting(store)), store, root, shared)
    }

    static func sharedRoots() async throws {
        let (context, store, root, shared) = try sharedFixture()
        defer { try? FileManager.default.removeItem(at: root) }
        try sharedPeople.write(to: shared.appendingPathComponent("people.frame"), atomically: true, encoding: .utf8)
        _ = try store.save(person.replacingOccurrences(of: "business.services", with: "team.people.alex"), to: "mine.frame")

        let library = store.library()
        try Expect.equal(library.problems, [], "all hold: \(library.problems)")
        try Expect.equal(library.items.map(\.id).sorted(), ["mine.role", "team.people.alex", "team.people.sam"], "shared entries under the root's name")
        try Expect.equal(library.item("team.people.sam")?.file, "team/people.frame", "files read through the root's folder")
        try Expect.true(library.groups.contains { $0.prefix == "team" && $0.entries == 2 }, "the root is a group")
        try Expect.true(library.instructions?.contains("team (2)") == true, "and every agent hears of it")

        let file = try await Context.Tools.File().call(.init(file: "team/people.frame"), in: context)
        try Expect.equal(file.text, sharedPeople, "a shared file reads through the root")
        try Expect.equal(file.file, shared.appendingPathComponent("people.frame").standardizedFileURL.path, "from the shared directory")

        let changed = sharedPeople.replacingOccurrences(of: "runs the workshops.\",", with: "runs workshops and follow-ups.\",")
        let saved = try await Context.Tools.Save().call(.init(file: "team/people.frame", text: changed), in: context)
        try Expect.true(saved.saved, "a shared file saves: \(saved.problems)")
        try Expect.equal(try String(contentsOf: shared.appendingPathComponent("people.frame"), encoding: .utf8), changed, "into the shared directory")
        try Expect.true(saved.archived?.hasPrefix(root.appendingPathComponent("archive").path) == true, "archived in this home: \(saved.archived ?? "-")")

        let added = try await Context.Tools.Save().call(.init(file: "team/clients/acme.frame", text: """
            import Context;
            let overview: Entry = .{ .title = "Acme", .summary = "A client.", .body = "Acme." };
            """), in: context)
        try Expect.true(added.saved && FileManager.default.fileExists(atPath: shared.appendingPathComponent("clients/acme.frame").path), "new files go into the shared directory")
        try Expect.true(store.library().item("team.clients.acme.overview") != nil, "and read back under the root")

        // A Mount file from before roots is refused as an unknown type.
        let mount = "import Context;\nlet shared: Mount = .{ .path = \"\(shared.path)\" };\n"
        let old = try await Context.Tools.Check().call(.init(file: "old.frame", text: mount), in: context)
        try Expect.false(old.valid, "Mount is gone: \(old.problems)")

        // A local file or folder of the root's name is refused.
        let clash = try await Context.Tools.Check().call(.init(file: "team.frame", text: person), in: context)
        try Expect.true(clash.problems.contains { $0.contains("name of a shared root") }, "a local file named like the root: \(clash.problems)")
        try FileManager.default.createDirectory(at: store.directory.appendingPathComponent("team"), withIntermediateDirectories: true)
        try person.replacingOccurrences(of: "business.services", with: "team.people.alex")
            .write(to: store.directory.appendingPathComponent("team/local.frame"), atomically: true, encoding: .utf8)
        try Expect.true(store.library().problems.contains { $0.contains("shared root 'team'") }, "a root and a local folder of one name: \(store.library().problems)")
    }

    static func readOnlyRoot() async throws {
        let (context, store, root, shared) = try sharedFixture(readOnly: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try sharedPeople.write(to: shared.appendingPathComponent("people.frame"), atomically: true, encoding: .utf8)
        try Expect.true(store.library().item("team.people.sam") != nil, "a read-only root still reads")

        let refused = try await Context.Tools.Save().call(.init(file: "team/people.frame", text: sharedPeople + "\n"), in: context)
        try Expect.false(refused.saved, "a root not declared writable is never written")
        try Expect.true(refused.problems.contains { $0.contains("not declared writable") }, "and says why: \(refused.problems)")
        try Expect.equal(try String(contentsOf: shared.appendingPathComponent("people.frame"), encoding: .utf8), sharedPeople, "the shared file is untouched")
    }
}
