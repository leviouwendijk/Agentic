import Agentic
import Foundation
import Macros
import Schema
import Tokens

public extension Context.Tools {
    @Tool("index")
    struct Index {
        @JSONSchema
        public struct Input: HashableSource {
            /// Only entries carrying any of these tags.
            public let tags: [String]?
            /// Only entries whose identifier starts with this, such as
            /// `people` or `clients.acme`.
            public let under: String?

            public init(tags: [String]? = nil, under: String? = nil) {
                self.tags = tags
                self.under = under
            }
        }

        @JSONSchema
        public struct Item: HashableResult {
            /// What context_tool_read takes: `business.services`.
            public let id: String
            public let title: String
            public let summary: String
            public let tags: [String]
            /// `always`: already in your instructions.
            public let load: String
            public let updated: String?
            /// The body's size, estimated.
            public let tokens: Int
            /// An agent's memory (below memories/): unreviewed, weighed
            /// below curated entries.
            public let memory: Bool
        }

        @JSONSchema
        public struct Group: HashableResult {
            /// A folder or file, as an identifier prefix: `hondenmeesters`,
            /// `hondenmeesters.team`. What `under` takes.
            public let prefix: String
            /// Entries below it.
            public let entries: Int
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let entries: [Item]
            /// Every group of the whole library, whatever the filters.
            public let groups: [Group]
            /// Files that do not hold; their entries are missing.
            public let problems: [String]
            /// Where the context files live.
            public let directory: String
        }

        public static let purpose =
            "What the owner has told agents about their world (business, people, clients, projects): every context entry with its summary and size, and agents' memories (memory: true, under memories). Read the bodies you need with context_tool_read. Narrow with tags or an identifier prefix."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            let library = Context.store(in: context).library()
            let selected = library.selecting(tags: input.tags, under: input.under)
            return .init(
                entries: selected.map { item in
                    .init(
                        id: item.id,
                        title: item.entry.title,
                        summary: item.entry.summary,
                        tags: item.entry.tags ?? [],
                        load: (item.entry.load ?? .onRequest).rawValue,
                        updated: item.entry.updated,
                        tokens: TokenEstimator.estimate(item.entry.body).estimatedTokens,
                        memory: Context.isMemoryFile(item.file)
                    )
                },
                groups: library.groups.map { .init(prefix: $0.prefix, entries: $0.entries) },
                problems: library.problems,
                directory: library.directory.path
            )
        }
    }

    @Tool("read")
    struct Read {
        @JSONSchema
        public struct Input: HashableSource {
            /// Identifiers from context_tool_index.
            public let ids: [String]

            public init(ids: [String]) {
                self.ids = ids
            }
        }

        @JSONSchema
        public struct Item: HashableResult {
            public let id: String
            public let title: String
            public let body: String
            public let updated: String?
            public let related: [String]
            /// The file that defines it, for context_tool_file.
            public let file: String
            /// Where it came from; set on memories.
            public let source: String?
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let entries: [Item]
            /// Identifiers no file defines.
            public let missing: [String]
        }

        public static let purpose =
            "The full text of context entries, by identifier from context_tool_index."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            let library = Context.store(in: context).library()
            var entries: [Item] = []
            var missing: [String] = []
            for id in input.ids {
                guard let item = library.item(id) else {
                    missing.append(id)
                    continue
                }
                entries.append(.init(
                    id: item.id,
                    title: item.entry.title,
                    body: item.entry.body,
                    updated: item.entry.updated,
                    related: item.entry.related ?? [],
                    file: item.file,
                    source: item.entry.source
                ))
            }
            return .init(entries: entries, missing: missing)
        }
    }

    @Tool("file")
    struct File {
        @JSONSchema
        public struct Input: HashableSource {
            /// Below context/, such as `business.frame` or `people/sam.frame`.
            public let file: String

            public init(file: String) {
                self.file = file
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let file: String
            /// The file as it is; absent when there is none yet.
            public let text: String?
            /// A complete file to start from.
            public let example: String
        }

        public static let purpose =
            "A context file's text, to change it with context_tool_save; or, when it does not exist yet, an example to start from."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            let store = Context.store(in: context)
            return .init(
                file: try store.url(input.file).path,
                text: try store.text(input.file),
                example: ContextFrame.example
            )
        }
    }
}
