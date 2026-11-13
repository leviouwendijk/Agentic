public protocol ToolRecovery: Producer {
    func classify(
        _ error: any Error,
        phase: ToolExecution.Phase,
        input: Input?
    ) -> Recovery.Incident?

    func reconcile(
        _ input: Input,
        after failure: ToolExecution.Failure,
        in context: ToolContext
    ) async throws -> ToolExecution.Reconciliation<Output>?
}

public extension ToolRecovery {
    func classify(
        _ error: any Error,
        phase: ToolExecution.Phase,
        input: Input?
    ) -> Recovery.Incident? {
        nil
    }

    func reconcile(
        _ input: Input,
        after failure: ToolExecution.Failure,
        in _: ToolContext
    ) async throws -> ToolExecution.Reconciliation<Output>? {
        nil
    }
}
