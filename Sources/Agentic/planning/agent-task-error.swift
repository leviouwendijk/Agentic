import Foundation

public enum AgentTaskError: Error, Sendable, LocalizedError {
    case durableStorageRequired
    case taskNotFound(AgentTaskIdentifier)
    case emptySubject
    case invalidTaskIdentifier(String)
    case noSubmittedAttempt(AgentTaskIdentifier)
    case invalidTransition(AgentTaskIdentifier, from: AgentTaskStatus, to: AgentTaskStatus)

    public var errorDescription: String? {
        switch self {
        case .durableStorageRequired:
            return "Task graph operations require durable Agentic task storage."

        case .taskNotFound(let id):
            return "No Agentic task exists for id '\(id.rawValue)'."

        case .emptySubject:
            return "Task subject cannot be empty."

        case .invalidTaskIdentifier(let value):
            return "Invalid task identifier '\(value)'."

        case .noSubmittedAttempt(let id):
            return "Task '\(id.rawValue)' has no submitted attempt awaiting a decision."

        case .invalidTransition(let id, let from, let to):
            return "Task '\(id.rawValue)' cannot move from \(from.rawValue) to \(to.rawValue)."
        }
    }
}
