import Agentic
import Workspace
import Primitives

public struct SearchTranscript: Tool {
    public typealias Input = SearchTranscriptInput
    public typealias Output = SearchTranscriptOutput

    public static let identifier: ToolIdentifier = "search_transcript"
    public static let description = "Search transcript events in an attached transcript store."
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

        return SearchTranscriptOutput(
                query: input.query,
                totalEventCount: events.count,
                matchCount: limitedMatches.count,
                matches: limitedMatches
            )
    }
}