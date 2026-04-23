public protocol AgentTranscriptStore: Sendable {
    func loadEvents() async throws -> [AgentTranscriptEvent]
    func append(_ event: AgentTranscriptEvent) async throws
}
