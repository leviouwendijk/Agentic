import Foundation

public enum AgentArtifactError: Error, Sendable, LocalizedError {
    case durableStorageRequired
    case artifactNotFound(String)
    case invalidArtifactIdentifier(String)
    case emptyContent
    case emptyFilename
    case unreadableContent(String)

    public var errorDescription: String? {
        switch self {
        case .durableStorageRequired:
            return "Artifact operations require durable Agentic artifact storage."

        case .artifactNotFound(let id):
            return "No Agentic artifact exists for id '\(id)'."

        case .invalidArtifactIdentifier(let id):
            return "Invalid artifact identifier '\(id)'."

        case .emptyContent:
            return "Artifact content cannot be empty."

        case .emptyFilename:
            return "Artifact filename cannot be empty."

        case .unreadableContent(let id):
            return "Artifact '\(id)' has unreadable content."
        }
    }
}
