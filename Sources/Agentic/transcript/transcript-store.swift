public protocol TranscriptStore: Sendable {
    func loadEvents() async throws -> [TranscriptEvent]
    func append(_ event: TranscriptEvent) async throws
}
