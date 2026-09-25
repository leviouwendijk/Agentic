import Agentic
import Workspace
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
        @JSONSchema
        public struct Input: HashableSource {
            /// Text query to search for in transcript events.
            public let query: String
            /// Transcript event kinds to search. An empty array includes all kinds.
            public let kinds: [TranscriptEventKind]
            /// Optional maximum number of search results.
            public let maxResults: Int?
            /// Whether to include full event text in search results.
            public let includeFullText: Bool
            /// Whether text matching is case-sensitive.
            public let caseSensitive: Bool

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

            public var clampedMaxResults: Int {
                max(
                    1,
                    min(
                        maxResults ?? 8,
                        50
                    )
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



        public let store: any AgentTranscriptStore

        public init(
            store: any AgentTranscriptStore
        ) {
            self.store = store
        }

        public func preflight(
            _ input: Input,
            workspace _: WorkspaceContext?
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
            workspace _: WorkspaceContext?
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
                    input.clampedMaxResults
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
