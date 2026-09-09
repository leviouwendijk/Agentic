public struct AgentModelInvocation: Sendable {
    public var request: AgentRequest
    public var selection: AgentModelSelection
    public var context: AgentModelInvocationContext
    public var metadata: [String: String]

    public init(
        request: AgentRequest,
        selection: AgentModelSelection = .executor,
        context: AgentModelInvocationContext = .default,
        metadata: [String: String] = [:]
    ) {
        self.request = request
        self.selection = selection
        self.context = context
        self.metadata = metadata
    }
}

/// The observable result of one routed model invocation.
///
/// `route` is the exact route record produced for `response` and, when a
/// route ledger is configured, the same value appended to that ledger.
public struct AgentModelInvocationResult: Sendable {
    public let response: AgentResponse
    public let route: AgentModelRouteRecord

    public init(
        response: AgentResponse,
        route: AgentModelRouteRecord
    ) {
        self.response = response
        self.route = route
    }
}

public enum AgentModelInvocationEvent: Sendable {
    case routed(AgentModelRouteResult)
    case model(AgentStreamEvent)
    case completed(AgentModelInvocationResult)
}

public protocol AgentModelInvoking: Sendable {
    func buffered(
        _ invocation: AgentModelInvocation
    ) async throws -> AgentModelInvocationResult

    func stream(
        _ invocation: AgentModelInvocation
    ) -> AsyncThrowingStream<AgentModelInvocationEvent, Error>
}
