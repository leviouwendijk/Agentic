import Agentic
import Workspace
import Primitives

public struct SummarizeTranscriptWindow: Tool {
    public typealias Input = SummarizeTranscriptWindowInput
    public typealias Output = SummarizeTranscriptWindowOutput

    public static let identifier: ToolIdentifier = "summarize_transcript_window"
    public static let description = "Create a deterministic summary of a transcript event window."
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

        return SummarizeTranscriptWindowOutput(
                window: window
            )
    }
}

private extension SummarizeTranscriptWindow {
    func summary(
        for input: SummarizeTranscriptWindowInput
    ) -> String {
        let limit = input.limit ?? 40

        if let startIndex = input.startIndex {
            return "Summarize up to \(limit) transcript event(s) from index \(startIndex)."
        }

        return "Summarize up to \(limit) transcript event(s)."
    }
}