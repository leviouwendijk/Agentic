import Foundation

enum FlowTestError: Error, LocalizedError, Sendable {
    case intentionalStreamFailure
    case unexpectedResult(String)

    var errorDescription: String? {
        switch self {
        case .intentionalStreamFailure:
            return "Intentional stream failure."

        case .unexpectedResult(let message):
            return message
        }
    }
}
