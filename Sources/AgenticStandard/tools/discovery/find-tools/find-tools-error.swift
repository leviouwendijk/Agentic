import Foundation

public enum FindToolsError:
    Error,
    Sendable,
    LocalizedError
{
    case emptyQuery

    public var errorDescription: String? {
        switch self {
        case .emptyQuery:
            "Tool 'find_tools' requires a non-empty capability query."
        }
    }
}
