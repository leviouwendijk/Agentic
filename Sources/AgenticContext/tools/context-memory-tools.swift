import Errors
import Agentic
import Foundation
import Frame
import Macros
import Schema

public extension Context {
    /// What agents learn across sessions, as entries in
    /// `memories/<area>.frame` (in the home's context, or a writable shared
    /// root's). Written one entry at a time by the memory tools, never
    /// loaded up front, reviewed and promoted by the context editor.
    enum Memories {
        /// `memories/sbm.frame`, or `team/memories/sbm.frame` in the shared
        /// root `team`.
        public static func file(area: String, root: String? = nil) -> String {
            (root.map { "\($0)/" } ?? "") + "\(Context.memoriesFolder)/\(area).frame"
        }

        /// `YYYY-MM-DD` in the local time zone, for `.updated`.
        public static func today(_ now: Date = Date()) -> String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = .current
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: now)
        }

        /// The memory file's text with `entry` bound as `name`: replaced in
        /// place when it exists, appended otherwise. A file's `Defaults`
        /// tags are folded into its entries.
        public static func remembering(
            _ entry: ContextFrame.Entry,
            as name: String,
            in text: String?,
            file: String
        ) -> (text: String, replaced: Bool, problems: [String]) {
            let current = entries(in: text, file: file)
            guard current.problems.isEmpty else {
                return ("", false, current.problems)
            }
            var bindings = current.bindings
            let replaced = bindings.contains { $0.name == name }
            if replaced {
                bindings = bindings.map { $0.name == name ? (name, entry) : $0 }
            } else {
                bindings.append((name, entry))
            }
            do {
                return (try render(bindings), replaced, [])
            } catch {
                return ("", replaced, ["\(file): \(error.explanation)"])
            }
        }

        /// The memory file's text without `name`; nil text when no entry
        /// is left.
        public static func forgetting(
            _ name: String,
            in text: String?,
            file: String
        ) -> (text: String?, problems: [String]) {
            let current = entries(in: text, file: file)
            guard current.problems.isEmpty else {
                return (nil, current.problems)
            }
            guard current.bindings.contains(where: { $0.name == name }) else {
                return (nil, ["\(file): no memory '\(name)'."])
            }
            let remaining = current.bindings.filter { $0.name != name }
            guard !remaining.isEmpty else {
                return (nil, [])
            }
            do {
                return (try render(remaining), [])
            } catch {
                return (nil, ["\(file): \(error.explanation)"])
            }
        }

        static func entries(
            in text: String?,
            file: String
        ) -> (bindings: [(name: String, entry: ContextFrame.Entry)], problems: [String]) {
            guard let text, let prefix = Context.idPrefix(of: file) else {
                return ([], [])
            }
            let read = Context.read(text, file: file)
            guard read.problems.isEmpty else {
                return ([], read.problems.map { "\($0) Fix the file with context_tool_file and context_tool_save first." })
            }
            return (read.items.map { (String($0.id.dropFirst(prefix.count + 1)), $0.entry) }, [])
        }

        static func render(
            _ bindings: [(name: String, entry: ContextFrame.Entry)]
        ) throws -> String {
            let document = try Frame.document(
                imports: [ContextFrame.module.name],
                bindings: bindings.map { (name: $0.name, type: ContextFrame.entryType, value: $0.entry) }
            )
            return """
                // Agents' memories, written by context_tool_remember and context_tool_forget.
                // Unreviewed: the context editor promotes, merges and forgets them.

                \(document.source)
                """
        }
    }
}

public extension Context.Tools {
    @Tool("remember")
    struct Remember {
        @JSONSchema
        public struct Input: HashableSource {
            /// The memory file, named like the context it belongs to:
            /// `sbm` (memories/sbm.frame) beside tools/sbm.frame, `owner`
            /// beside owner.frame.
            public let area: String
            /// The entry's binding name, such as `live_products`; an
            /// existing memory of that name is replaced.
            public let name: String
            /// A shared root to write in instead of this home, such as
            /// `hondenmeesters`; only for what concerns that team.
            public let root: String?
            public let title: String
            /// One line: what the index shows.
            public let summary: String
            /// The fact, then `Why:` and `How to apply:`.
            public let body: String
            /// Its kind (`feedback`, `project`, `reference`, `owner`) and
            /// topics; `memory` is added.
            public let tags: [String]?
            /// Context entries it relates to; each must exist.
            public let related: [String]?
            /// Where it came from, such as the conversation or document;
            /// `agentic session, <today>` when left out.
            public let source: String?

            public init(
                area: String,
                name: String,
                root: String? = nil,
                title: String,
                summary: String,
                body: String,
                tags: [String]? = nil,
                related: [String]? = nil,
                source: String? = nil
            ) {
                self.area = area
                self.name = name
                self.root = root
                self.title = title
                self.summary = summary
                self.body = body
                self.tags = tags
                self.related = related
                self.source = source
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let saved: Bool
            /// The memory's identifier: `memories.sbm.live_products`.
            public let id: String?
            /// An existing memory of that name was replaced.
            public let replaced: Bool
            public let file: String
            /// The previous file, kept.
            public let archived: String?
            /// Why it was not saved.
            public let problems: [String]
        }

        public static let purpose =
            "Remember something for later sessions: save one memory entry in context/memories/<area>.frame, replacing one of the same name. For corrections and confirmed approaches from the owner (with why), facts about ongoing work the code does not record, and where things are. Search first and update an existing memory instead of adding a near-duplicate. Never secrets."
        public static let risk: ActionRisk = .boundedmutate

        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            let store = Context.store(in: context)
            let file = Context.Memories.file(area: input.area, root: input.root)
            let path = (try? store.url(file).path) ?? file
            func refused(_ problems: [String], replaced: Bool = false) -> Output {
                .init(saved: false, id: nil, replaced: replaced, file: path, archived: nil, problems: problems)
            }
            guard Context.isIdentifierComponent(input.area), Frame.isIdentifier(input.name) else {
                return refused(["area must hold only letters, digits, _ and -, and name must be an identifier, such as live_products."])
            }
            var tags = ["memory"]
            for tag in input.tags ?? [] where !tags.contains(tag) {
                tags.append(tag)
            }
            let today = Context.Memories.today()
            let source = input.source?.trimmingCharacters(in: .whitespacesAndNewlines)
            let entry = ContextFrame.Entry(
                title: input.title,
                summary: input.summary,
                body: input.body,
                tags: tags,
                updated: today,
                related: input.related.flatMap { $0.isEmpty ? nil : $0 },
                source: source.flatMap { $0.isEmpty ? nil : $0 } ?? "agentic session, \(today)"
            )
            let written = Context.Memories.remembering(entry, as: input.name, in: try store.text(file), file: file)
            guard written.problems.isEmpty else {
                return refused(written.problems)
            }
            let check = Context.check(written.text, file: file, in: store)
            guard check.problems.isEmpty else {
                return refused(check.problems, replaced: written.replaced)
            }
            let archived = try store.save(written.text, to: file)
            return .init(
                saved: true,
                id: check.entries.first { $0.hasSuffix(".\(input.name)") },
                replaced: written.replaced,
                file: path,
                archived: archived?.path,
                problems: []
            )
        }
    }

    @Tool("forget")
    struct Forget {
        @JSONSchema
        public struct Input: HashableSource {
            /// The memory file: `sbm` for memories/sbm.frame.
            public let area: String
            /// The memory's binding name.
            public let name: String
            /// The shared root it is in, if not this home.
            public let root: String?

            public init(area: String, name: String, root: String? = nil) {
                self.area = area
                self.name = name
                self.root = root
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let removed: Bool
            public let file: String
            /// The previous file, kept.
            public let archived: String?
            /// Why it was not removed.
            public let problems: [String]
        }

        public static let purpose =
            "Forget a memory that turned out wrong, stale or duplicated: remove one entry from context/memories/<area>.frame (the file goes when it is the last). Refused while another entry relates to it."
        public static let risk: ActionRisk = .boundedmutate

        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            let store = Context.store(in: context)
            let file = Context.Memories.file(area: input.area, root: input.root)
            let path = (try? store.url(file).path) ?? file
            func refused(_ problems: [String]) -> Output {
                .init(removed: false, file: path, archived: nil, problems: problems)
            }
            guard Context.isIdentifierComponent(input.area), Frame.isIdentifier(input.name) else {
                return refused(["area must hold only letters, digits, _ and -, and name must be an identifier."])
            }
            let written = Context.Memories.forgetting(input.name, in: try store.text(file), file: file)
            guard written.problems.isEmpty else {
                return refused(written.problems)
            }
            guard let text = written.text else {
                if try store.isReadOnly(file) {
                    return refused([Context.StoreFailure.readOnly(file).explanation])
                }
                let broken = store.library().removing(file).problems
                guard broken.isEmpty else {
                    return refused(broken)
                }
                let archived = try store.remove(file)
                return .init(removed: true, file: path, archived: archived?.path, problems: [])
            }
            let check = Context.check(text, file: file, in: store)
            guard check.problems.isEmpty else {
                return refused(check.problems)
            }
            let archived = try store.save(text, to: file)
            return .init(removed: true, file: path, archived: archived?.path, problems: [])
        }
    }
}
