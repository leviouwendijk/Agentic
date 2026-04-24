public protocol AgentArtifactStore: Sendable {
    func emit(
        _ draft: AgentArtifactDraft
    ) async throws -> AgentArtifactRecord

    func list(
        kinds: [AgentArtifactKind],
        latestFirst: Bool,
        limit: Int?
    ) async throws -> [AgentArtifact]

    func load(
        id: String
    ) async throws -> AgentArtifactRecord?
}
