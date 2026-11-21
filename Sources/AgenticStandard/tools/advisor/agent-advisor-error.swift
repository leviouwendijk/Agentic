import Foundation

public enum AgentAdvisorError: Error, Sendable, LocalizedError {
    case emptyPrompt

    public var errorDescription: String? {
        switch self {
        case .emptyPrompt:
            return "Tool 'standard_tool_advisor_ask' requires a non-empty prompt."
        }
    }
}
