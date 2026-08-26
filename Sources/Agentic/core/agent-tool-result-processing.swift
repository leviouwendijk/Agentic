public struct AgentToolResultProcessing:
    Sendable,
    Codable,
    Hashable
{
    public let projection: AgentToolResultProjection?
    public let observations: [AgentToolResultObservation]

    public init(
        projection: AgentToolResultProjection? = nil,
        observations: [AgentToolResultObservation] = []
    ) {
        self.projection = projection
        self.observations = observations
    }

    public var isEmpty: Bool {
        projection == nil
            && observations.isEmpty
    }

    public static let none = Self()
}
