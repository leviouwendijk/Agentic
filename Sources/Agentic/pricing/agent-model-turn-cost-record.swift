import Foundation

public struct AgentModelTurnCostRecord: Sendable, Codable, Hashable, Identifiable {
    public var id: String
    public var turnIndex: Int
    public var requestModel: String?
    public var projected: AgentCostProjection?
    public var actual: AgentCostProjection?
    public var createdAt: Date
    public var updatedAt: Date
    public var metadata: [String: String]

    public init(
        id: String = UUID().uuidString,
        turnIndex: Int,
        requestModel: String? = nil,
        projected: AgentCostProjection? = nil,
        actual: AgentCostProjection? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.turnIndex = max(
            0,
            turnIndex
        )
        self.requestModel = requestModel
        self.projected = projected
        self.actual = actual
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.metadata = metadata
    }
}
