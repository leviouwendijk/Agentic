public protocol AgentTaskStore: Sendable {
    func load(
        id: AgentTaskIdentifier
    ) async throws -> AgentTask?

    func list() async throws -> [AgentTask]

    func save(
        _ task: AgentTask
    ) async throws

    func delete(
        id: AgentTaskIdentifier
    ) async throws
}
