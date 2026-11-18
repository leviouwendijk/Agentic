import Agentic
import Foundation
import Macros
import Schema
import Search

public extension Context.Tools {
    @Tool("context_search")
    struct Search {
        @JSONSchema
        public enum Strategy: String, Sendable, Codable, Hashable, CaseIterable {
            /// Tolerates typos and partial words. The default.
            case fuzzy
            /// The words as written, anywhere.
            case contains
            /// Whole identifier-like words.
            case identifier
            /// A regular expression (ICU); `^` and `$` match at line ends.
            case regex
        }

        @JSONSchema
        public struct Input: HashableSource {
            /// One or more queries; an entry matching several ranks higher.
            public let queries: [String]
            /// Only entries carrying any of these tags.
            public let tags: [String]?
            /// Only entries below this group, such as `hondenmeesters`.
            public let under: String?
            /// Where to look: title, summary, tags, body. All by default.
            public let fields: [String]?
            public let strategy: Strategy?
            /// At most this many entries; 10 by default.
            public let limit: Int?

            public init(
                queries: [String],
                tags: [String]? = nil,
                under: String? = nil,
                fields: [String]? = nil,
                strategy: Strategy? = nil,
                limit: Int? = nil
            ) {
                self.queries = queries
                self.tags = tags
                self.under = under
                self.fields = fields
                self.strategy = strategy
                self.limit = limit
            }
        }

        @JSONSchema
        public struct Line: HashableResult {
            /// From the body's first line.
            public let number: Int
            public let text: String
        }

        @JSONSchema
        public struct Match: HashableResult {
            public let id: String
            public let title: String
            public let summary: String
            /// Which fields matched.
            public let fields: [String]
            /// Higher is better; title and summary matches weigh more than
            /// body matches.
            public let score: Int
            /// Body lines that matched; read the whole entry with
            /// context_read.
            public let lines: [Line]
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let matches: [Match]
            /// Files that do not hold; their entries were not searched.
            public let problems: [String]
        }

        public static let purpose =
            "Search the owner's context entries (title, summary, tags and body) for words or names, ranked, with the body lines that matched. Use it when you do not know which entry holds something; then read the best matches with context_read."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            let library = Context.store(in: context).library()
            let fields = try (input.fields ?? []).map { name in
                guard let field = Context.Field(rawValue: name) else {
                    throw Context.SearchFailure.unknownField(name)
                }
                return field
            }
            let strategy: SearchStrategy = switch input.strategy ?? .fuzzy {
            case .fuzzy: .fuzzy
            case .contains: .contains
            case .identifier: .identifier
            case .regex: .regex
            }
            let matches = library.search(
                input.queries,
                in: library.selecting(tags: input.tags, under: input.under),
                fields: fields.isEmpty ? Context.Field.allCases : fields,
                strategy: strategy,
                limit: input.limit ?? 10
            )
            return .init(
                matches: matches.map { match in
                    .init(
                        id: match.item.id,
                        title: match.item.entry.title,
                        summary: match.item.entry.summary,
                        fields: match.fields.map(\.rawValue),
                        score: match.score,
                        lines: match.lines.map { .init(number: $0.number, text: $0.text) }
                    )
                },
                problems: library.problems
            )
        }
    }
}

public extension Context {
    enum SearchFailure: Error, LocalizedError, Sendable, Hashable {
        case unknownField(String)

        public var errorDescription: String? {
            switch self {
            case .unknownField(let name):
                return "'\(name)' is not a field; search title, summary, tags or body."
            }
        }
    }
}
