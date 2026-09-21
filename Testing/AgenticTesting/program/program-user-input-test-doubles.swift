import Agentic

public struct FixedProgramUserInput: ProgramUserInputInvoking {
    public let response: UserInputResponse

    public init(
        response: UserInputResponse
    ) {
        self.response = response
    }

    public func ask(
        _ request: UserInputRequest
    ) async throws -> UserInputResponse {
        _ = request
        return response
    }
}

public enum ProgramUserInputTestError:
    Error,
    Sendable,
    Equatable
{
    case responsesExhausted
}

public actor RecordingProgramUserInput: ProgramUserInputInvoking {
    private var responses: [UserInputResponse]
    private var requests: [UserInputRequest] = []

    public init(
        responses: [UserInputResponse]
    ) {
        self.responses = responses
    }

    public init(
        response: UserInputResponse
    ) {
        self.responses = [response]
    }

    public func ask(
        _ request: UserInputRequest
    ) async throws -> UserInputResponse {
        requests.append(request)

        guard !responses.isEmpty else {
            throw ProgramUserInputTestError.responsesExhausted
        }

        return responses.removeFirst()
    }

    public func recordedRequests() -> [UserInputRequest] {
        requests
    }

    public func remainingResponseCount() -> Int {
        responses.count
    }
}
