import Agentic
import Workspace
import Primitives
import Schema
import Macros

public extension Standard.Tools {
    @Tool
    struct ReadTranscriptEvents: Tool {
        @JSONSchema
        public struct Input: Source, Hashable {
            /// Optional first transcript event index to read.
            public let startIndex: Int?
            /// Optional maximum number of transcript events to return.
            public let limit: Int?
            /// Exact event identifiers to include. An empty array does not restrict by identifier.
            public let eventIDs: [String]
            /// Transcript event kinds to include. An empty array includes all kinds.
            public let kinds: [TranscriptEventKind]
            /// Whether to include full event text instead of compact excerpts.
            public let includeFullText: Bool
            /// Whether to return matching events in reverse chronological order.
            public let latestFirst: Bool

            public init(
                startIndex: Int? = nil,
                limit: Int? = nil,
                eventIDs: [String] = [],
                kinds: [TranscriptEventKind] = [],
                includeFullText: Bool = false,
                latestFirst: Bool = false
            ) {
                self.startIndex = startIndex
                self.limit = limit
                self.eventIDs = eventIDs
                self.kinds = kinds
                self.includeFullText = includeFullText
                self.latestFirst = latestFirst
            }
        }

        @JSONSchema
        public struct Output: Result, Hashable {
            public let totalEventCount: Int
            public let returnedEventCount: Int
            public let events: [TranscriptEventRecord]

            public init(
                totalEventCount: Int,
                returnedEventCount: Int,
                events: [TranscriptEventRecord]
            ) {
                self.totalEventCount = totalEventCount
                self.returnedEventCount = returnedEventCount
                self.events = events
            }
        }

        public static let purpose = "Read selected transcript events from an attached transcript store."

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

            let selected: [(index: Int, event: AgentTranscriptEvent)]
            if input.eventIDs.isEmpty {
                selected = TranscriptSupport.selectedEvents(
                    from: events,
                    startIndex: input.startIndex,
                    limit: input.limit,
                    allowedKinds: input.kinds,
                    latestFirst: input.latestFirst
                )
            } else {
                let requestedIDs = Set(
                    input.eventIDs
                )

                selected = events.enumerated().compactMap { index, event in
                    guard requestedIDs.contains(event.id) else {
                        return nil
                    }

                    guard TranscriptSupport.matchesKinds(
                        event,
                        allowedKinds: input.kinds
                    ) else {
                        return nil
                    }

                    return (
                        index: index,
                        event: event
                    )
                }
            }

            let records = selected.map { indexedEvent in
                TranscriptSupport.record(
                    for: indexedEvent.event,
                    index: indexedEvent.index,
                    includeFullText: input.includeFullText
                )
            }

            return Output(
                totalEventCount: events.count,
                returnedEventCount: records.count,
                events: records
            )
        }
    }
}

private extension Standard.Tools.ReadTranscriptEvents {
    func summary(
        for input: Input
    ) -> String {
        if !input.eventIDs.isEmpty {
            return "Read \(input.eventIDs.count) transcript event(s) by id."
        }

        let limit = input.limit ?? 40

        if let startIndex = input.startIndex {
            return "Read up to \(limit) transcript event(s) from index \(startIndex)."
        }

        return "Read up to \(limit) transcript event(s)."
    }
}
