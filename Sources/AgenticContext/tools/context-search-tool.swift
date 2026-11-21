import Agentic
import Foundation
import Macros
import Schema
import Search

public extension Context.Tools {
    @Tool("search")
    struct Search {
        @JSONSchema
        public enum Strategy: String, Sendable, Codable, Hashable, CaseIterable {
            /// Tolerates typos and partial words. The default.
            case fuzzy
            /// The text as written, anywhere.
            case contains
            /// Whole identifier-like words.
            case identifier
            /// A regular expression (ICU); `^` and `$` match at line ends.
            case regex

            var search: SearchStrategy {
                switch self {
                case .fuzzy: .fuzzy
                case .contains: .contains
                case .identifier: .identifier
                case .regex: .regex
                }
            }
        }

        @JSONSchema
        public enum Role: String, Sendable, Codable, Hashable, CaseIterable {
            /// Every entry returned matches it.
            case required
            /// Ranks entries that match it higher.
            case preferred
            /// No entry returned matches it.
            case excluded
        }

        @JSONSchema
        public struct Probe: HashableSource {
            public let text: String
            /// preferred by default.
            public let role: Role?
            /// The search's strategy by default.
            public let strategy: Strategy?

            public init(text: String, role: Role? = nil, strategy: Strategy? = nil) {
                self.text = text
                self.role = role
                self.strategy = strategy
            }
        }

        @JSONSchema
        public struct Input: HashableSource {
            /// The short form: terms that rank entries (preferred probes).
            public let queries: [String]?
            /// Terms with roles: required (every result matches), preferred
            /// (ranks), excluded (no result matches). Combined with queries.
            public let probes: [Probe]?
            /// Search only these entries, such as the ids of a previous
            /// result, to narrow it.
            public let within: [String]?
            /// Only entries carrying any of these tags.
            public let tags: [String]?
            /// Only entries below this group, such as `hondenmeesters`.
            public let under: String?
            /// Only entries updated on or after this day (YYYY-MM-DD).
            public let updated_from: String?
            /// Only entries updated on or before this day (YYYY-MM-DD).
            public let updated_to: String?
            /// Where to look: title, summary, tags, body. All by default.
            public let fields: [String]?
            /// For probes without their own; fuzzy by default.
            public let strategy: Strategy?
            /// Defaults to false.
            public let case_sensitive: Bool?
            /// At most this many entries; 10 by default.
            public let limit: Int?
            /// Skip this many ranked entries, to page; 0 by default.
            public let offset: Int?

            public init(
                queries: [String]? = nil,
                probes: [Probe]? = nil,
                within: [String]? = nil,
                tags: [String]? = nil,
                under: String? = nil,
                updated_from: String? = nil,
                updated_to: String? = nil,
                fields: [String]? = nil,
                strategy: Strategy? = nil,
                case_sensitive: Bool? = nil,
                limit: Int? = nil,
                offset: Int? = nil
            ) {
                self.queries = queries
                self.probes = probes
                self.within = within
                self.tags = tags
                self.under = under
                self.updated_from = updated_from
                self.updated_to = updated_to
                self.fields = fields
                self.strategy = strategy
                self.case_sensitive = case_sensitive
                self.limit = limit
                self.offset = offset
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
            /// context_tool_read.
            public let lines: [Line]
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let matches: [Match]
            /// Every entry that matched, before limit and offset.
            public let total: Int
            /// Pass as offset for the next page; absent on the last page.
            public let next_offset: Int?
            /// Files that do not hold; their entries were not searched.
            public let problems: [String]
        }

        public static let purpose =
            "Search the owner's context entries (title, summary, tags and body), ranked, with the body lines that matched. Combine required, preferred and excluded terms; narrow by tags, group, date or a previous result's ids (within). Then read the best matches with context_tool_read."
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
            let probes = (input.queries ?? []).map { Context.Probe($0) }
                + (input.probes ?? []).map { probe in
                    Context.Probe(
                        probe.text,
                        role: Context.Probe.Role(rawValue: (probe.role ?? .preferred).rawValue) ?? .preferred,
                        strategy: probe.strategy?.search
                    )
                }
            let limit = input.limit ?? 10
            let offset = input.offset ?? 0
            let result = try library.search(
                probes,
                in: library.selecting(
                    tags: input.tags,
                    under: input.under,
                    within: input.within,
                    updatedFrom: input.updated_from,
                    updatedTo: input.updated_to
                ),
                fields: fields.isEmpty ? Context.Field.allCases : fields,
                strategy: input.strategy?.search,
                caseSensitive: input.case_sensitive ?? false,
                limit: limit,
                offset: offset
            )
            return .init(
                matches: result.matches.map { match in
                    .init(
                        id: match.item.id,
                        title: match.item.entry.title,
                        summary: match.item.entry.summary,
                        fields: match.fields.map(\.rawValue),
                        score: match.score,
                        lines: match.lines.map { .init(number: $0.number, text: $0.text) }
                    )
                },
                total: result.total,
                next_offset: offset + result.matches.count < result.total ? offset + result.matches.count : nil,
                problems: library.problems
            )
        }
    }
}
