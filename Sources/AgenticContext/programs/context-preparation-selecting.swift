import Agentic

public extension Context {
    /// Preparation candidates must already have source-validated revisions.
    /// This is an opt-in invocation seam, not an authorization bypass.
    protocol PreparationSelecting: Sendable {
        func allocations(for request: AgentRequest) async throws -> [Allocation]
    }
}
