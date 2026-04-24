public struct AgentRunResult: Sendable, Codable, Hashable {
    public let sessionID: String
    public let response: AgentResponse?
    public let pendingApproval: PendingApproval?
    public let state: AgentLoopState
    public let events: [AgentRunEvent]
    public let costRecord: AgentCostRecord?

    public init(
        sessionID: String,
        response: AgentResponse?,
        pendingApproval: PendingApproval? = nil,
        state: AgentLoopState,
        events: [AgentRunEvent] = [],
        costRecord: AgentCostRecord? = nil
    ) {
        self.sessionID = sessionID
        self.response = response
        self.pendingApproval = pendingApproval
        self.state = state
        self.events = events
        self.costRecord = costRecord
    }

    public static func completed(
        sessionID: String,
        response: AgentResponse,
        state: AgentLoopState,
        events: [AgentRunEvent] = [],
        costRecord: AgentCostRecord? = nil
    ) -> Self {
        .init(
            sessionID: sessionID,
            response: response,
            pendingApproval: nil,
            state: state,
            events: events,
            costRecord: costRecord
        )
    }

    public static func awaitingApproval(
        sessionID: String,
        response: AgentResponse,
        pendingApproval: PendingApproval,
        state: AgentLoopState,
        events: [AgentRunEvent] = [],
        costRecord: AgentCostRecord? = nil
    ) -> Self {
        .init(
            sessionID: sessionID,
            response: response,
            pendingApproval: pendingApproval,
            state: state,
            events: events,
            costRecord: costRecord
        )
    }

    public var isCompleted: Bool {
        response != nil && pendingApproval == nil
    }

    public var isAwaitingApproval: Bool {
        pendingApproval != nil
    }
}
