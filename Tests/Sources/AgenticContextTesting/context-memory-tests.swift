import Agentic
import AgenticContext
import Foundation
import Testing

/// Memories: entries below memories/, written one at a time by
/// context_remember and context_forget.
enum ContextMemoryTests {
    static func memory(load: String? = nil, source: String? = "session T, 2026-11-21") -> String {
        """
        import Context;

        let note: Entry = .{
            .title = "A note",
            .summary = "Something learned.",\(load.map { "\n    .load = .\($0)," } ?? "")\(source.map { "\n    .source = \"\($0)\"," } ?? "")
            .body = "The fact.",
        };
        """
    }

    static func rules() throws {
        try Expect.equal(Context.read(memory(), file: "memories/sbm.frame").problems, [], "a memory with a source holds")
        try Expect.true(
            Context.read(memory(load: "always"), file: "memories/sbm.frame").problems.first?.contains("never loaded always") == true,
            "a memory is never loaded always"
        )
        try Expect.true(
            Context.read(memory(source: nil), file: "team/memories/sbm.frame").problems.first?.contains("needs .source") == true,
            "a memory needs a source, in a shared root too"
        )
        try Expect.equal(Context.read(memory(load: "always", source: nil), file: "tools/sbm.frame").problems, [], "curated files keep their freedom")
    }

    static func renderRoundTrip() throws {
        let entry = ContextFrame.Entry(
            title: "Live products",
            summary: "Products that reach real services go in .live.",
            body: "Declare them in .live.\n\nWhy: --all runs undeclared products.",
            tags: ["memory", "feedback"],
            updated: "2026-11-21",
            related: ["business.services"],
            source: "session T, 2026-11-21"
        )
        let written = Context.Memories.remembering(entry, as: "live_products", in: nil, file: "memories/sbm.frame")
        try Expect.equal(written.problems, [], "renders")
        try Expect.false(written.replaced, "new")
        try Expect.true(written.text.hasPrefix("// Agents' memories"), "marked as tool-written")
        let read = Context.read(written.text, file: "memories/sbm.frame")
        try Expect.equal(read.problems, [], "reads back")
        try Expect.equal(read.items.first?.entry, entry, "every field survives, the block body too")
    }

    static func rememberAndForget() async throws {
        let (context, store, root) = try ContextFilesTests.fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        _ = try store.save(ContextFrame.example, to: "business.frame")

        let remember = Context.Tools.Remember()
        let first = try await remember.call(.init(
            area: "sbm",
            name: "live_products",
            title: "Live products",
            summary: "Products that reach real services go in .live.",
            body: "Declare them in .live.",
            tags: ["feedback", "memory"],
            related: ["business.services"]
        ), in: context)
        try Expect.true(first.saved, "saved: \(first.problems)")
        try Expect.equal(first.id, "memories.sbm.live_products", "identified by area and name")
        try Expect.false(first.replaced, "new")
        let saved = store.library().item("memories.sbm.live_products")?.entry
        try Expect.equal(saved?.tags, ["memory", "feedback"], "memory first, once")
        try Expect.equal(saved?.updated, Context.Memories.today(), "dated today")
        try Expect.equal(saved?.source, "agentic session, \(Context.Memories.today())", "a source when none is given")

        let again = try await remember.call(.init(
            area: "sbm", name: "live_products", title: "Live products", summary: "Updated.", body: "Still .live.", source: "a review"
        ), in: context)
        try Expect.true(again.saved && again.replaced, "the same name replaces")
        try Expect.notNil(again.archived, "the previous file is archived")
        _ = try await remember.call(.init(area: "sbm", name: "wipe_steps", title: "Wipe", summary: "Wipe after.", body: "Use wipe."), in: context)
        try Expect.equal(
            store.library().items.filter { $0.file == "memories/sbm.frame" }.map(\.id),
            ["memories.sbm.live_products", "memories.sbm.wipe_steps"],
            "replaced in place, new appended"
        )

        let index = try await Context.Tools.Index().call(.init(under: "memories"), in: context)
        try Expect.true(index.entries.allSatisfy(\.memory), "the index marks memories")
        let curated = try await Context.Tools.Index().call(.init(under: "business"), in: context)
        try Expect.false(curated.entries.contains(where: \.memory), "and only memories")
        let read = try await Context.Tools.Read().call(.init(ids: ["memories.sbm.live_products"]), in: context)
        try Expect.equal(read.entries.first?.source, "a review", "read returns the source")

        let unknown = try await remember.call(.init(
            area: "sbm", name: "broken", title: "x", summary: "x", body: "x", related: ["nobody.here"]
        ), in: context)
        try Expect.false(unknown.saved, "a relation to nothing is refused")
        let badName = try await remember.call(.init(area: "s b", name: "x", title: "x", summary: "x", body: "x"), in: context)
        try Expect.false(badName.saved, "an area that is not a path component is refused")

        _ = try store.save("""
            import Context;

            let rules: Entry = .{
                .title = "Rules",
                .summary = "Relates to a memory.",
                .related = ["memories.sbm.wipe_steps"],
                .body = "See the memory.",
            };
            """, to: "tools.frame")
        let forget = Context.Tools.Forget()
        let removed = try await forget.call(.init(area: "sbm", name: "live_products"), in: context)
        try Expect.true(removed.removed, "forgotten: \(removed.problems)")
        let held = try await forget.call(.init(area: "sbm", name: "wipe_steps"), in: context)
        try Expect.false(held.removed, "refused while an entry relates to it")
        try Expect.true(held.problems.first?.contains("memories.sbm.wipe_steps") == true, "and says which: \(held.problems)")

        _ = try store.remove("tools.frame")
        let last = try await forget.call(.init(area: "sbm", name: "wipe_steps"), in: context)
        try Expect.true(last.removed, "the last memory: \(last.problems)")
        try Expect.isNil(try store.text("memories/sbm.frame"), "takes the file with it")
        try Expect.notNil(last.archived, "archived first")
        let missing = try await forget.call(.init(area: "sbm", name: "wipe_steps"), in: context)
        try Expect.false(missing.removed, "nothing left to forget")
    }
}
