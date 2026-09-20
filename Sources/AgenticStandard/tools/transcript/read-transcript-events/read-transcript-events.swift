import Agentic
import Workspace
import Primitives

public struct ReadTranscriptEvents: Tool {
    public typealias Input = ReadTranscriptEventsInput
    public typealias Output = ReadTranscriptEventsOutput

    public static let identifier: ToolIdentifier = "read_transcript_events"
    public static let description = "Read selected transcript events from an attached transcript store."
    public static let risk: ActionRisk = .observe
    public static let definition = ToolDefinition(
        identifier: identifier,
        purpose: description,
        risk: risk
    )

    public var identifier: ToolIdentifier {
        Self.identifier
    }

    public var description: String {
        Self.description
    }

    public var risk: ActionRisk {
        Self.risk
    }

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

        return .init(
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

        return ReadTranscriptEventsOutput(
                totalEventCount: events.count,
                returnedEventCount: records.count,
                events: records
            )
    }
}

private extension ReadTranscriptEvents {
    func summary(
        for input: ReadTranscriptEventsInput
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