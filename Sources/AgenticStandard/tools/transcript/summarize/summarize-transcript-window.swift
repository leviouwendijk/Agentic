import Agentic
import Workspace
import Primitives
import Schema
import Macros

public extension Standard.Tools {
    @Tool
    struct SummarizeTranscriptWindow: Tool {
        @JSONSchema
        public struct Input: Source, Hashable {
            /// Optional first transcript event index for the summary window.
            public let startIndex: Int?
            /// Optional maximum number of transcript events in the summary window.
            public let limit: Int?
            /// Transcript event kinds to include. An empty array includes all kinds.
            public let kinds: [TranscriptEventKind]
            /// Whether to traverse the selected transcript window newest first.
            public let latestFirst: Bool
            /// Optional maximum excerpt characters retained per summarized event.
            public let maxExcerptCharacters: Int?

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

            public var clampedMaxExcerptCharacters: Int {
                max(
                    32,
                    min(
                        maxExcerptCharacters ?? 220,
                        2_000
                    )
                )
            }
        }

        @JSONSchema
        public struct Output: Result, Hashable {
            public let window: TranscriptWindowSummary

            public init(
                window: TranscriptWindowSummary
            ) {
                self.window = window
            }
        }

        public static let purpose = "Create a deterministic summary of a transcript event window."

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
                summary: summary(
                    for: input
                ),
                sideEffects: []
            )
        }

        public func call(
            _ input: Input,
            workspace _: WorkspaceContext?
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
                maxExcerptCharacters: input.clampedMaxExcerptCharacters
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
