import Agentic

public enum ScriptedModelFailure:
    Error,
    Sendable,
    Equatable
{
    case scripted(String)
    case responsesExhausted(AgentModelResponseDelivery)

    public init(
        message: String
    ) {
        self = .scripted(message)
    }

    public var message: String {
        switch self {
        case .scripted(let message):
            message

        case .responsesExhausted(let delivery):
            "No scripted \(delivery.rawValue) model response remains."
        }
    }
}

public enum ScriptedOutcome<Value: Sendable>: Sendable {
    case success(Value)
    case failure(ScriptedModelFailure)
}

public struct ScriptedModelInvocation: Sendable {
    public let delivery: AgentModelResponseDelivery
    public let request: AgentRequest
    public let route: AgentModelRoute
    public let context: AgentModelInvocationContext

    public init(
        delivery: AgentModelResponseDelivery,
        request: AgentRequest,
        route: AgentModelRoute,
        context: AgentModelInvocationContext
    ) {
        self.delivery = delivery
        self.request = request
        self.route = route
        self.context = context
    }
}

private actor ScriptedModelResponseState {
    private var bufferedOutcomes: [ScriptedOutcome<AgentResponse>]
    private var streamOutcomes: [ScriptedOutcome<[AgentStreamEvent]>]
    private var invocations: [ScriptedModelInvocation] = []

    init(
        bufferedOutcomes: [ScriptedOutcome<AgentResponse>],
        streamOutcomes: [ScriptedOutcome<[AgentStreamEvent]>]
    ) {
        self.bufferedOutcomes = bufferedOutcomes
        self.streamOutcomes = streamOutcomes
    }

    func nextBuffered(
        request: AgentRequest,
        route: AgentModelRoute,
        context: AgentModelInvocationContext
    ) -> ScriptedOutcome<AgentResponse> {
        invocations.append(
            ScriptedModelInvocation(
                delivery: .buffered,
                request: request,
                route: route,
                context: context
            )
        )

        guard !bufferedOutcomes.isEmpty else {
            return .failure(
                .responsesExhausted(.buffered)
            )
        }

        return bufferedOutcomes.removeFirst()
    }

    func nextStream(
        request: AgentRequest,
        route: AgentModelRoute,
        context: AgentModelInvocationContext
    ) -> ScriptedOutcome<[AgentStreamEvent]> {
        invocations.append(
            ScriptedModelInvocation(
                delivery: .stream,
                request: request,
                route: route,
                context: context
            )
        )

        guard !streamOutcomes.isEmpty else {
            return .failure(
                .responsesExhausted(.stream)
            )
        }

        return streamOutcomes.removeFirst()
    }

    func recordedInvocations() -> [ScriptedModelInvocation] {
        invocations
    }

    func remainingBufferedResponseCount() -> Int {
        bufferedOutcomes.count
    }

    func remainingStreamResponseCount() -> Int {
        streamOutcomes.count
    }
}

public struct ScriptedModelResponses:
    AgentModelResponseProviding,
    Sendable
{
    private let state: ScriptedModelResponseState

    public init(
        buffered: [ScriptedOutcome<AgentResponse>] = [],
        stream: [ScriptedOutcome<[AgentStreamEvent]>] = []
    ) {
        self.state = ScriptedModelResponseState(
            bufferedOutcomes: buffered,
            streamOutcomes: stream
        )
    }

    public init(
        buffered: ScriptedOutcome<AgentResponse>,
        stream: ScriptedOutcome<[AgentStreamEvent]>
    ) {
        self.init(
            buffered: [buffered],
            stream: [stream]
        )
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

    public func recordedInvocations() async -> [ScriptedModelInvocation] {
        await state.recordedInvocations()
    }

    public func remainingBufferedResponseCount() async -> Int {
        await state.remainingBufferedResponseCount()
    }

    public func remainingStreamResponseCount() async -> Int {
        await state.remainingStreamResponseCount()
    }

    public func buffered(
        request: AgentRequest,
        route: AgentModelRoute,
        context: AgentModelInvocationContext
    ) async throws -> AgentResponse {
        let outcome = await state.nextBuffered(
            request: request,
            route: route,
            context: context
        )

        switch outcome {
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
        let state = self.state

        return AsyncThrowingStream { continuation in
            Task {
                let outcome = await state.nextStream(
                    request: request,
                    route: route,
                    context: context
                )

                switch outcome {
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
