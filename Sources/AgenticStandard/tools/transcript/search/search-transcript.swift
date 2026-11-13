import Agentic
import Primitives
import Schema
import Macros

@JSONSchema
public struct SearchTranscriptMatch: Sendable, Codable, Hashable {
    public let score: Int
    public let event: TranscriptEventRecord

    public init(
        score: Int,
        event: TranscriptEventRecord
    ) {
        self.score = score
        self.event = event
    }
}

public extension Standard.Tools {
    @Tool
    struct SearchTranscript: Tool {
        public struct Input: HashableSource, CodableInvariant {
            @JSONSchema
            public struct Raw: HashableSource {
                /// Text query to search for in transcript events.
                public var query: String
                /// Transcript event kinds to search. An empty array includes all kinds.
                public var kinds: [TranscriptEventKind]
                /// Optional maximum number of search results.
                public var maxResults: Int?
                /// Whether to include full event text in search results.
                public var includeFullText: Bool
                /// Whether text matching is case-sensitive.
                public var caseSensitive: Bool

                public init(
                    query: String,
                    kinds: [TranscriptEventKind] = [],
                    maxResults: Int? = nil,
                    includeFullText: Bool = false,
                    caseSensitive: Bool = false
                ) {
                    self.query = query
                    self.kinds = kinds
                    self.maxResults = maxResults
                    self.includeFullText = includeFullText
                    self.caseSensitive = caseSensitive
                }
            }

            public let query: String
            public let kinds: [TranscriptEventKind]
            /// Defaults to 8; clamped to 1...50.
            public let maxResults: Int
            public let includeFullText: Bool
            public let caseSensitive: Bool

            public init(_ raw: Raw) {
                self.query = raw.query
                self.kinds = raw.kinds
                self.maxResults = max(1, min(raw.maxResults ?? 8, 50))
                self.includeFullText = raw.includeFullText
                self.caseSensitive = raw.caseSensitive
            }

            public init(
                query: String,
                kinds: [TranscriptEventKind] = [],
                maxResults: Int? = nil,
                includeFullText: Bool = false,
                caseSensitive: Bool = false
            ) {
                self.init(
                    Raw(
                        query: query,
                        kinds: kinds,
                        maxResults: maxResults,
                        includeFullText: includeFullText,
                        caseSensitive: caseSensitive
                    )
                )
            }

            public var raw: Raw {
                Raw(
                    query: query,
                    kinds: kinds,
                    maxResults: maxResults,
                    includeFullText: includeFullText,
                    caseSensitive: caseSensitive
                )
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let query: String
            public let totalEventCount: Int
            public let matchCount: Int
            public let matches: [SearchTranscriptMatch]

            public init(
                query: String,
                totalEventCount: Int,
                matchCount: Int,
                matches: [SearchTranscriptMatch]
            ) {
                self.query = query
                self.totalEventCount = totalEventCount
                self.matchCount = matchCount
                self.matches = matches
            }
        }

        public static let purpose = "Search transcript events in an attached transcript store."

        public static let risk: ActionRisk = .observe



        public let store: any TranscriptStore

        public init(
            store: any TranscriptStore
        ) {
            self.store = store
        }

        public func preflight(
            _ input: Input,
            in _: ToolContext
        ) async throws -> ToolPreflight {
            .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Search transcript for '\(input.query)'",
                sideEffects: []
            )
        }

        public func call(
            _ input: Input,
            in _: ToolContext
        ) async throws -> Output {
            let events = try await store.loadEvents()

            let matches = events.enumerated().compactMap { index, event -> SearchTranscriptMatch? in
                guard TranscriptSupport.matchesKinds(
                    event,
                    allowedKinds: input.kinds
                ) else {
                    return nil
                }

                guard TranscriptSupport.containsQuery(
                    event,
                    query: input.query,
                    caseSensitive: input.caseSensitive
                ) else {
                    return nil
                }

                let score = TranscriptSupport.score(
                    event,
                    query: input.query,
                    caseSensitive: input.caseSensitive
                )

                return .init(
                    score: score,
                    event: TranscriptSupport.record(
                        for: event,
                        index: index,
                        includeFullText: input.includeFullText
                    )
                )
            }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.event.index > rhs.event.index
                }

                return lhs.score > rhs.score
            }

            let limitedMatches = Array(
                matches.prefix(
                    input.maxResults
                )
            )

            return Output(
                query: input.query,
                totalEventCount: events.count,
                matchCount: limitedMatches.count,
                matches: limitedMatches
            )
        }
    }
}
