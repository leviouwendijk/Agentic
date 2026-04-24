import Foundation

public struct AgentCostRecord: Sendable, Codable, Hashable, Identifiable {
    public var id: String
    public var sessionID: String?
    public var runID: String?
    public var model: String?
    public var projected: AgentCostProjection?
    public var actual: AgentCostProjection?
    public var turns: [AgentModelTurnCostRecord]
    public var createdAt: Date
    public var updatedAt: Date
    public var metadata: [String: String]

    public init(
        id: String = UUID().uuidString,
        sessionID: String? = nil,
        runID: String? = nil,
        model: String? = nil,
        projected: AgentCostProjection? = nil,
        actual: AgentCostProjection? = nil,
        turns: [AgentModelTurnCostRecord] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.sessionID = sessionID
        self.runID = runID
        self.model = model
        self.projected = projected
        self.actual = actual
        self.turns = turns
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.metadata = metadata
    }
}

public extension AgentCostRecord {
    func appendingOrReplacingTurn(
        _ turn: AgentModelTurnCostRecord
    ) -> AgentCostRecord {
        var record = self
        record.updatedAt = Date()

        if let index = record.turns.firstIndex(where: { $0.turnIndex == turn.turnIndex }) {
            record.turns[index] = turn
        } else {
            record.turns.append(
                turn
            )
            record.turns.sort { lhs, rhs in
                lhs.turnIndex < rhs.turnIndex
            }
        }

        if let projected = turn.projected {
            record.projected = projected
        }

        if let actual = turn.actual {
            record.actual = actual
        }

        if record.model == nil {
            record.model = turn.requestModel
        }

        return record
    }

    func updatingTurnActual(
        turnIndex: Int,
        actual: AgentCostProjection
    ) -> AgentCostRecord {
        var record = self
        record.updatedAt = Date()
        record.actual = actual

        if let index = record.turns.firstIndex(where: { $0.turnIndex == turnIndex }) {
            record.turns[index].actual = actual
            record.turns[index].updatedAt = Date()
        } else {
            record.turns.append(
                .init(
                    turnIndex: turnIndex,
                    requestModel: model,
                    actual: actual
                )
            )
            record.turns.sort { lhs, rhs in
                lhs.turnIndex < rhs.turnIndex
            }
        }

        return record
    }
}
