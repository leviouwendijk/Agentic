import Agentic
import Macros
import Schema

@JSONSchema
public struct SummarizeTranscriptWindowOutput: Sendable, Codable, Hashable {
    public let window: TranscriptWindowSummary

    public init(
        window: TranscriptWindowSummary
    ) {
        self.window = window
    }
}
