import Agentic

public struct ScriptedModelFailure:
    Error,
    Sendable,
    Equatable
{
    public let message: String

    public init(
        message: String
    ) {
        self.message = message
    }
}

public enum ScriptedOutcome<Value: Sendable>: Sendable {
    case success(Value)
    case failure(ScriptedModelFailure)
}

public struct ScriptedModelResponses:
    AgentModelResponseProviding,
    Sendable
{
    public let bufferedOutcome: ScriptedOutcome<AgentResponse>
    public let streamOutcome: ScriptedOutcome<[AgentStreamEvent]>

    public init(
        buffered: ScriptedOutcome<AgentResponse>,
        stream: ScriptedOutcome<[AgentStreamEvent]>
    ) {
        self.bufferedOutcome = buffered
        self.streamOutcome = stream
    }

    public static func successful(
        _ response: AgentResponse
    ) -> Self {
        .init(
            buffered: .success(response),
            stream: .success([
                .completed(response),
            ])
        )
    }

    public static func failing(
        _ message: String
    ) -> Self {
        let failure = ScriptedModelFailure(
            message: message
        )

        return .init(
            buffered: .failure(failure),
            stream: .failure(failure)
        )
    }

    public func buffered(
        request: AgentRequest,
        route: AgentModelRoute,
        context: AgentModelInvocationContext
    ) async throws -> AgentResponse {
        _ = request
        _ = route
        _ = context

        switch bufferedOutcome {
        case .success(let response):
            return response

        case .failure(let failure):
            throw failure
        }
    }

    public func stream(
        request: AgentRequest,
        route: AgentModelRoute,
        context: AgentModelInvocationContext
    ) -> AsyncThrowingStream<AgentStreamEvent, Error> {
        _ = request
        _ = route
        _ = context

        return AsyncThrowingStream { continuation in
            switch streamOutcome {
            case .success(let events):
                for event in events {
                    continuation.yield(event)
                }
                continuation.finish()

            case .failure(let failure):
                continuation.finish(
                    throwing: failure
                )
            }
        }
    }
}

public struct ScriptedModelGateway:
    AgentModelGateway,
    Sendable
{
    public let identifier: AgentModelGatewayIdentifier
    public let responses: ScriptedModelResponses

    public init(
        identifier: AgentModelGatewayIdentifier = .init(
            rawValue: "scripted_testing"
        ),
        responses: ScriptedModelResponses
    ) {
        self.identifier = identifier
        self.responses = responses
    }

    public var response: AgentModelResponseProviding {
        responses
    }
}
