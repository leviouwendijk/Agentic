import Agentic
import AgenticContext
import Foundation
import Testing

/// The context library over real files: identifiers from paths, the
/// index and read tools, and a save that checks, archives and refuses.
enum ContextFilesTests {
    static func fixture() throws -> (ToolContext, Context.Store, URL) {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("agentic-context-\(UUID().uuidString)", isDirectory: true)
        let store = Context.Store(
            directory: root.appendingPathComponent("context", isDirectory: true),
            archiveDirectory: root.appendingPathComponent("archive/context", isDirectory: true)
        )
        return (ToolContext(services: try ToolServices().inserting(store)), store, root)
    }

    static let person = """
        import Context;

        let role: Entry = .{
            .title = "Sam",
            .summary = "Co-owner; runs the workshops.",
            .tags = ["people"],
            .related = ["business.services"],
            .body = \"\"\"
                Sam runs the workshops and most follow-ups.
                \"\"\",
        };
        """

    static func exampleHolds() throws {
        let read = Context.read(ContextFrame.example, file: "business.frame")
        try Expect.equal(read.problems, [], "the example holds")
        try Expect.equal(read.items.map(\.id), ["business.overview", "business.services", "business.voice"], "identifiers from file and binding")
        try Expect.equal(read.items.first { $0.id == "business.voice" }?.entry.load, .always, "load decodes")
        try Expect.true(read.items[0].entry.body.hasPrefix("Northbank Studio is"), "block strings dedent")
    }

    static func libraryIdentifiers() throws {
        let (_, store, root) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        try Expect.equal(store.library().items.count, 0, "a missing directory is an empty library")

        _ = try store.save(ContextFrame.example, to: "business.frame")
        _ = try store.save(person, to: "people/sam.frame")
        _ = try store.save("import Context;\nlet x: Entry = .{ .title = \"x\" };\n", to: "broken.frame")
        let library = store.library()
        try Expect.equal(library.items.map(\.id).sorted(), ["business.overview", "business.services", "business.voice", "people.sam.role"], "folders become identifier segments")
        try Expect.true(library.problems.contains { $0.hasPrefix("broken.frame:") }, "a broken file is reported: \(library.problems)")
        try Expect.equal(library.always.map(\.id), ["business.voice"], "always entries")
        try Expect.true(library.instructions?.contains("Alex & Sam") == true, "always bodies become instructions")
    }

    static func indexAndRead() async throws {
        let (context, store, root) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        _ = try store.save(ContextFrame.example, to: "business.frame")
        _ = try store.save(person, to: "people/sam.frame")

        let all = try await Context.Tools.Index().call(.init(), in: context)
        try Expect.equal(all.entries.count, 4, "every entry")
        try Expect.true(all.entries.allSatisfy { $0.tokens > 0 }, "sizes")
        let pricing = try await Context.Tools.Index().call(.init(tags: ["pricing"]), in: context)
        try Expect.equal(pricing.entries.map(\.id), ["business.services"], "by tag")
        let people = try await Context.Tools.Index().call(.init(under: "people"), in: context)
        try Expect.equal(people.entries.map(\.id), ["people.sam.role"], "by prefix")

        let read = try await Context.Tools.Read().call(.init(ids: ["people.sam.role", "people.nobody"]), in: context)
        try Expect.equal(read.entries.map(\.file), ["people/sam.frame"], "the body and its file")
        try Expect.equal(read.missing, ["people.nobody"], "unknown identifiers")
    }

    static func checkAndSave() async throws {
        let (context, _, root) = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        let save = Context.Tools.Save()

        let dangling = try await save.call(.init(file: "people/sam.frame", text: person), in: context)
        try Expect.false(dangling.saved, "a relation to nothing is refused")
        try Expect.true(dangling.problems.contains { $0.contains("business.services") }, "names it: \(dangling.problems)")

        let escape = try await save.call(.init(file: "../settings.frame", text: ContextFrame.example), in: context)
        try Expect.false(escape.saved, "paths stay below context/")

        let typo = ContextFrame.example.replacingOccurrences(of: ".summary = \"A two-person", with: ".sumary = \"A two-person")
        let schema = try await Context.Tools.Check().call(.init(file: "business.frame", text: typo), in: context)
        try Expect.true(schema.problems.contains { $0.hasPrefix("business.frame:") && $0.contains("sumary") }, "a typo with its place: \(schema.problems)")

        let date = ContextFrame.example.replacingOccurrences(of: "2026-01-15", with: "15-01-2026")
        let badDate = try await Context.Tools.Check().call(.init(file: "business.frame", text: date), in: context)
        try Expect.false(badDate.valid, "dates are YYYY-MM-DD")

        let first = try await save.call(.init(file: "business.frame", text: ContextFrame.example), in: context)
        try Expect.true(first.saved, "saved: \(first.problems)")
        try Expect.equal(first.archived, nil, "nothing to archive")
        let related = try await save.call(.init(file: "people/sam.frame", text: person), in: context)
        try Expect.true(related.saved, "its relation exists now: \(related.problems)")

        let withoutServices = "import Context;\nlet overview: Entry = .{ .title = \"t\", .summary = \"s\", .body = \"b\" };\n"
        let breaking = try await save.call(.init(file: "business.frame", text: withoutServices), in: context)
        try Expect.false(breaking.saved, "removing what another file relates to is refused: \(breaking.problems)")

        let refined = ContextFrame.example.replacingOccurrences(of: "120 euros", with: "125 euros")
        let second = try await save.call(.init(file: "business.frame", text: refined), in: context)
        try Expect.true(second.saved, "a refinement saves")
        let archived = try String(contentsOf: URL(fileURLWithPath: second.archived ?? "/missing"), encoding: .utf8)
        try Expect.equal(archived, ContextFrame.example, "the previous file is archived whole")
        try Expect.true(second.archived?.hasSuffix("archive/context/" + (second.archived.map { URL(fileURLWithPath: $0).lastPathComponent } ?? "")) == true, "archived below archive/context")

        // Archives are the only copies: Writers makes no backups of its own.
        let made = try FileManager.default.subpathsOfDirectory(atPath: root.path)
        try Expect.true(!made.contains { $0.contains("safe-file-backups") || $0.contains(".bak") }, "no Writers backups: \(made)")
    }
}
