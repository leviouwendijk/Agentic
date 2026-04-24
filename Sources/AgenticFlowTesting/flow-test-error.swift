import Foundation

enum FlowTestError: Error, LocalizedError, Sendable {
    case intentionalStreamFailure
    case unexpectedResult(String)
    case assertionFailed(String)

    var errorDescription: String? {
        switch self {
        case .intentionalStreamFailure:
            return "Intentional stream failure."

        case .unexpectedResult(let message):
            return message

        case .assertionFailed(let message):
            return message
        }
    }
}
