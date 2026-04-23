import Foundation

public enum AgentHistoryError: Error, Sendable, LocalizedError {
    case historyStoreRequired
    case checkpointNotFound(String)
    case corruptedCheckpoint(String)

    public var errorDescription: String? {
        switch self {
        case .historyStoreRequired:
            return "This operation requires an attached AgentHistoryStore."

        case .checkpointNotFound(let sessionID):
            return "No history checkpoint exists for session '\(sessionID)'."

        case .corruptedCheckpoint(let reason):
            return "The saved history checkpoint is incomplete or corrupted: \(reason)"
        }
    }
}
