import Errors
import Foundation
import Primitives

extension ToolExecutionEngine {
    enum Error:
        Swift.Error,
        LocalizedError
    {
        case reconciliation_unsupported
        case reconciliation_unresolved
        case applied_without_output
        case preflight_changed
        case prepared_retry_requires_reconciliation
        case recovery_exhausted
        case action_unsupported(Recovery.Action)

        var errorDescription: String? {
            switch self {
            case .reconciliation_unsupported:
                return "Tool does not support reconciliation for the classified failure."

            case .reconciliation_unresolved:
                return "Tool reconciliation could not determine whether the operation was applied."

            case .applied_without_output:
                return "Tool reconciliation confirmed the operation was applied but could not reconstruct the tool output."

            case .preflight_changed:
                return "Tool preflight changed after reconciliation; retry requires fresh approval."
            case .prepared_retry_requires_reconciliation:
                return "A prepared operation cannot be automatically replayed; reconcile its original attempt."

            case .recovery_exhausted:
                return "Tool recovery exhausted its authored mechanical recovery plan."

            case .action_unsupported(let action):
                return "Tool execution does not mechanically execute recovery action '\(action.rawValue)'."
            }
        }
    }

    /// The model's answer for a failed call, through the session's
    /// payload guard like any other result.
    func makeErrorResult(
        for call: ToolInvocation,
        error: any Swift.Error
    ) async throws -> FunctionCall.Response {
        try await FunctionCall.Response.toolError(
            call: .init(call.reference),
            error: error,
            guard: context.payloadGuard
        )
    }
}

extension ToolExecutionEngine.Error:
    ErrorNamespaced,
    ErrorDispositionProviding
{
    static let errorNamespace = "agentic.tool_execution"

    var errorCode: String {
        switch self {
        case .reconciliation_unsupported:
            return "reconciliation_unsupported"

        case .reconciliation_unresolved:
            return "reconciliation_unresolved"

        case .applied_without_output:
            return "applied_without_output"

        case .preflight_changed:
            return "preflight_changed"

        case .prepared_retry_requires_reconciliation:
            return "prepared_retry_requires_reconciliation"

        case .recovery_exhausted:
            return "recovery_exhausted"

        case .action_unsupported:
            return "action_unsupported"
        }
    }

    var errorDisposition: ErrorDisposition? {
        switch self {
        case .preflight_changed:
            // The changed call needs fresh approval.
            return .requires_access

        case .recovery_exhausted,
             .action_unsupported,
             .reconciliation_unsupported,
             .reconciliation_unresolved,
             .prepared_retry_requires_reconciliation:
            return .permanent

        case .applied_without_output:
            return nil
        }
    }
}
