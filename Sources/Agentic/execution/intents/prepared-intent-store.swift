
public protocol PreparedIntentStore: Sendable {
    func load(
        id: PreparedIntentIdentifier
    ) async throws -> PreparedIntent?

    func list() async throws -> [PreparedIntent]

    /// Create only when the identifier does not yet exist. Never overwrite.
    func insert(
        _ intent: PreparedIntent
    ) async throws -> Bool

    /// Atomically replace exactly the observed record; false means it changed.
    /// Implementations MUST arbitrate concurrent callers, including independent
    /// store instances sharing the same durable backing store.
    func replace(
        _ intent: PreparedIntent,
        matching expected: PreparedIntent
    ) async throws -> Bool

    func delete(
        id: PreparedIntentIdentifier
    ) async throws
}
