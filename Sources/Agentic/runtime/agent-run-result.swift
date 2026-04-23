public struct AgentRunResult: Sendable, Codable, Hashable {
    public let sessionID: String
    public let response: AgentResponse?
    public let pendingApproval: PendingApproval?
    public let state: AgentLoopState
    public let events: [AgentRunEvent]

    public init(
        sessionID: String,
        response: AgentResponse?,
        pendingApproval: PendingApproval? = nil,
        state: AgentLoopState,
        events: [AgentRunEvent] = []
    ) {
        self.sessionID = sessionID
        self.response = response
        self.pendingApproval = pendingApproval
        self.state = state
        self.events = events
    }

    public static func completed(
        sessionID: String,
        response: AgentResponse,
        state: AgentLoopState,
        events: [AgentRunEvent] = []
    ) -> Self {
        .init(
            sessionID: sessionID,
            response: response,
            pendingApproval: nil,
            state: state,
            events: events
        )
    }

    public static func awaitingApproval(
        sessionID: String,
        response: AgentResponse,
        pendingApproval: PendingApproval,
        state: AgentLoopState,
        events: [AgentRunEvent] = []
    ) -> Self {
        .init(
            sessionID: sessionID,
            response: response,
            pendingApproval: pendingApproval,
            state: state,
            events: events
        )
    }

    public var isCompleted: Bool {
        response != nil && pendingApproval == nil
    }

    public var isAwaitingApproval: Bool {
        pendingApproval != nil
    }
}
