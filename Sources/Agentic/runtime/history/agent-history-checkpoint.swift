import Foundation

public enum AgentHistoryPhase: String, Sendable, Codable, Hashable, CaseIterable {
    case ready_for_model
    case processing_tool_calls
    case awaiting_approval
    case completed
}

public struct AgentHistoryCheckpoint: Sendable, Codable, Hashable, Identifiable {
    public let id: String
    public let originalRequest: AgentRequest
    public var state: AgentLoopState
    public var events: [AgentRunEvent]
    public var phase: AgentHistoryPhase
    public var lastResponse: AgentResponse?
    public var pendingApproval: PendingApproval?
    public var costRecord: AgentCostRecord?
    public var updatedAt: Date

    public init(
        id: String,
        originalRequest: AgentRequest,
        state: AgentLoopState,
        events: [AgentRunEvent] = [],
        phase: AgentHistoryPhase = .ready_for_model,
        lastResponse: AgentResponse? = nil,
        pendingApproval: PendingApproval? = nil,
        costRecord: AgentCostRecord? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.originalRequest = originalRequest
        self.state = state
        self.events = events
        self.phase = phase
        self.lastResponse = lastResponse
        self.pendingApproval = pendingApproval
        self.costRecord = costRecord
        self.updatedAt = updatedAt
    }
}

public extension AgentHistoryCheckpoint {
    var session: AgentSession {
        .init(
            id: id,
            messages: state.messages
        )
    }

    mutating func touch(
        now: Date = Date()
    ) {
        updatedAt = now
    }
}
