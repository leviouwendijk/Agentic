import Foundation

public enum AgentHistoryPhase: String, Sendable, Codable, Hashable, CaseIterable {
    case ready_for_model
    case processing_tool_calls
    case suspended
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
    public var suspension: AgentSuspension?
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
        suspension: AgentSuspension? = nil,
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
        self.suspension = suspension
        self.pendingApproval = pendingApproval ?? suspension?.pendingApproval
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

    var resolvedSuspension: AgentSuspension? {
        if let suspension {
            return suspension
        }

        if let pendingApproval {
            return .approval(
                pendingApproval
            )
        }

        return nil
    }

    var pendingUserInput: PendingUserInput? {
        resolvedSuspension?.pendingUserInput
    }

    mutating func suspend(
        _ suspension: AgentSuspension
    ) {
        self.suspension = suspension
        self.pendingApproval = suspension.pendingApproval
        self.phase = .suspended
    }

    mutating func clearSuspension() {
        suspension = nil
        pendingApproval = nil

        if phase == .suspended || phase == .awaiting_approval {
            phase = .ready_for_model
        }
    }

    mutating func touch(
        now: Date = Date()
    ) {
        updatedAt = now
    }
}
