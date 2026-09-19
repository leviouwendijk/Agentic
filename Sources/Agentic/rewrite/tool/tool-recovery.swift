import Workspace

public protocol ToolRecovery: Producer {
    func classify(
        _ error: any Error,
        phase: ToolCall.Phase,
        input: Input?
    ) -> Recovery.Incident?

    func reconcile(
        _ input: Input,
        after failure: ToolCall.Failure,
        workspace: WorkspaceContext?
    ) async throws -> ToolCall.Reconciliation<Output>?
}

public extension ToolRecovery {
    func classify(
        _ error: any Error,
        phase: ToolCall.Phase,
        input: Input?
    ) -> Recovery.Incident? {
        nil
    }

    func reconcile(
        _ input: Input,
        after failure: ToolCall.Failure,
        workspace: WorkspaceContext?
    ) async throws -> ToolCall.Reconciliation<Output>? {
        nil
    }
}

