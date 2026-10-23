import Foundation
import Version

public enum PreparedIntentError: Error, Sendable, LocalizedError {
    case durableStorageRequired
    case intentNotFound(PreparedIntentIdentifier)
    case emptyExecutionSummary
    case intentAlreadyExists(PreparedIntentIdentifier)
    case concurrentModification(PreparedIntentIdentifier)
    case executionAttemptMismatch(expected: String?, actual: String?)
    case notDeletable(PreparedIntentIdentifier, PreparedIntentStatus)
    case notReviewable(PreparedIntentIdentifier, PreparedIntentStatus)
    case expired(PreparedIntentIdentifier)
    case notApproved(PreparedIntentIdentifier, PreparedIntentStatus)
    case executionRecordIntentMismatch(
        expected: PreparedIntentIdentifier,
        actual: PreparedIntentIdentifier
    )
    case executionRecordOperationMismatch(
        expected: PreparedOperation.Schema,
        actual: PreparedOperation.Schema
    )
    case executionResultSchemaMismatch(
        expected: PreparedOperation.Schema,
        actual: PreparedOperation.Schema
    )

    public var errorDescription: String? {
        switch self {
        case .durableStorageRequired:
            return "Prepared intent operations require durable Agentic storage."

        case .intentNotFound(let id):
            return "No prepared intent exists for id '\(id.rawValue)'."

        case .intentAlreadyExists(let id):
            return "Prepared intent '\(id.rawValue)' already exists."

        case .notDeletable(let id, let status):
            return "Prepared intent '\(id.rawValue)' cannot be deleted in state '\(status.rawValue)'."

        case .concurrentModification(let id):
            return "Prepared intent '\(id.rawValue)' changed concurrently; reload before transitioning."

        case .executionAttemptMismatch(let expected, let actual):
            return "Execution attempt '\(actual ?? "none")' does not match claimed attempt '\(expected ?? "none")'."

        case .emptyExecutionSummary:
            return "Prepared intent execution summary cannot be empty."

        case .notReviewable(let id, let status):
            return "Prepared intent '\(id.rawValue)' cannot be reviewed while its status is '\(status.rawValue)'."

        case .expired(let id):
            return "Prepared intent '\(id.rawValue)' has expired."

        case .notApproved(let id, let status):
            return "Prepared intent '\(id.rawValue)' is not executable because its status is '\(status.rawValue)'."

        case .executionRecordIntentMismatch(let expected, let actual):
            return "Execution record intent id '\(actual.rawValue)' does not match prepared intent '\(expected.rawValue)'."

        case .executionRecordOperationMismatch(let expected, let actual):
            return "Execution record operation '\(actual.identifier.rawValue)' version \(actual.version.string(prefixStyle: .none)) does not match prepared operation '\(expected.identifier.rawValue)' version \(expected.version.string(prefixStyle: .none))."

        case .executionResultSchemaMismatch(let expected, let actual):
            return "Execution result schema '\(actual.identifier.rawValue)' version \(actual.version.string(prefixStyle: .none)) does not match prepared operation '\(expected.identifier.rawValue)' version \(expected.version.string(prefixStyle: .none))."
        }
    }
}
