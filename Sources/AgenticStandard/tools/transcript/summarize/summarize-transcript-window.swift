import Agentic
import Primitives
import Schema
import Macros

public extension Standard.Tools {
    @Tool
    struct SummarizeTranscriptWindow: Tool {
        public struct Input: HashableSource, CodableInvariant {
            @JSONSchema
            public struct Raw: HashableSource {
                /// Optional first transcript event index for the summary window.
                public var startIndex: Int?
                /// Optional maximum number of transcript events in the summary window.
                public var limit: Int?
                /// Transcript event kinds to include. An empty array includes all kinds.
                public var kinds: [TranscriptEventKind]
                /// Whether to traverse the selected transcript window newest first.
                public var latestFirst: Bool
                /// Optional maximum excerpt characters retained per summarized event.
                public var maxExcerptCharacters: Int?

                public init(
                    startIndex: Int? = nil,
                    limit: Int? = nil,
                    kinds: [TranscriptEventKind] = [],
                    latestFirst: Bool = false,
                    maxExcerptCharacters: Int? = nil
                ) {
                    self.startIndex = startIndex
                    self.limit = limit
                    self.kinds = kinds
                    self.latestFirst = latestFirst
                    self.maxExcerptCharacters = maxExcerptCharacters
                }
            }

            public let startIndex: Int?
            public let limit: Int?
            public let kinds: [TranscriptEventKind]
            public let latestFirst: Bool
            /// Defaults to 220; clamped to 32...2000.
            public let maxExcerptCharacters: Int

            public init(_ raw: Raw) {
                self.startIndex = raw.startIndex
                self.limit = raw.limit
                self.kinds = raw.kinds
                self.latestFirst = raw.latestFirst
                self.maxExcerptCharacters = max(32, min(raw.maxExcerptCharacters ?? 220, 2_000))
            }

            public init(
                startIndex: Int? = nil,
                limit: Int? = nil,
                kinds: [TranscriptEventKind] = [],
                latestFirst: Bool = false,
                maxExcerptCharacters: Int? = nil
            ) {
                self.init(
                    Raw(
                        startIndex: startIndex,
                        limit: limit,
                        kinds: kinds,
                        latestFirst: latestFirst,
                        maxExcerptCharacters: maxExcerptCharacters
                    )
                )
            }

            public var raw: Raw {
                Raw(
                    startIndex: startIndex,
                    limit: limit,
                    kinds: kinds,
                    latestFirst: latestFirst,
                    maxExcerptCharacters: maxExcerptCharacters
                )
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let window: TranscriptWindowSummary

            public init(
                window: TranscriptWindowSummary
            ) {
                self.window = window
            }
        }

        public static let purpose = "Create a deterministic summary of a transcript event window."

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
                summary: summary(
                    for: input
                ),
                sideEffects: []
            )
        }

        public func call(
            _ input: Input,
            in _: ToolContext
        ) async throws -> Output {
            let events = try await store.loadEvents()
            let selected = TranscriptSupport.selectedEvents(
                from: events,
                startIndex: input.startIndex,
                limit: input.limit,
                allowedKinds: input.kinds,
                latestFirst: input.latestFirst
            )

            let window = TranscriptSupport.summarize(
                events: selected,
                totalEventCount: events.count,
                maxExcerptCharacters: input.maxExcerptCharacters
            )

            return Output(
                window: window
            )
        }
    }
}

private extension Standard.Tools.SummarizeTranscriptWindow {
    func summary(
        for input: Input
    ) -> String {
        let limit = input.limit ?? 40

        if let startIndex = input.startIndex {
            return "Summarize up to \(limit) transcript event(s) from index \(startIndex)."
        }

        return "Summarize up to \(limit) transcript event(s)."
    }
}
