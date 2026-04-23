import Foundation

public enum ToolDispatchError: Error, Sendable, LocalizedError {
    case unknownTool(String)

    public var errorDescription: String? {
        switch self {
        case .unknownTool(let name):
            return "Unknown tool: \(name)"
        }
    }
}
