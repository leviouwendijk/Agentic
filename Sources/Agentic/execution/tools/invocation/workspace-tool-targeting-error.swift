import Foundation

public enum WorkspaceToolTargetingError:
    Error,
    Sendable,
    LocalizedError,
    Equatable
{
    case workspaceRequired(String)

    public var errorDescription: String? {
        switch self {
        case .workspaceRequired(let toolName):
            return "Tool '\(toolName)' requires a workspace context for workspace targeting."
        }
    }
}
