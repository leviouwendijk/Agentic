import Agentic
import Foundation

public extension Intents {
    enum Error: Swift.Error, Sendable, Hashable, LocalizedError {
        case invalidID(String)
        case notFound(Intent.ID)
        case alreadyExists(Intent.ID)
        case concurrentModification(Intent.ID)
        case notReviewable(Intent.ID, Intent.Status)
        case notApproved(Intent.ID, Intent.Status)
        case expired(Intent.ID)
        case attemptMismatch(Intent.ID, expected: String?, actual: String)

        public var errorDescription: String? {
            switch self {
            case .invalidID(let raw):
                return "'\(raw)' is not an intent id: use letters, digits, '-' and '_'."

            case .notFound(let id):
                return "No intent '\(id)'."

            case .alreadyExists(let id):
                return "Intent '\(id)' already exists."

            case .concurrentModification(let id):
                return "Intent '\(id)' changed while it was being updated; read it again."

            case .notReviewable(let id, let status):
                return "Intent '\(id)' is \(status.rawValue) and can no longer be reviewed."

            case .notApproved(let id, let status):
                return "Intent '\(id)' is \(status.rawValue); only approved intents run."

            case .expired(let id):
                return "Intent '\(id)' has expired."

            case .attemptMismatch(let id, let expected, let actual):
                return "Intent '\(id)' is claimed by attempt '\(expected ?? "none")', not '\(actual)'."
            }
        }
    }
}
