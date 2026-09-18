// MOVE: AgenticExecution — result processing is execution-layer orchestration,
// not semantic Tool result state. Projection now lives canonically at
// ToolCall.ResultProjection; execution observations will be migrated separately.
// The old declaration is intentionally left commented until that move lands.
//
// public struct AgentToolResultProcessing:
//     Sendable,
//     Codable,
//     Hashable
// {
//     public let projection: AgentToolResultProjection?
//     public let observations: [AgentToolResultObservation]
//
//     public init(
//         projection: AgentToolResultProjection? = nil,
//         observations: [AgentToolResultObservation] = []
//     ) {
//         self.projection = projection
//         self.observations = observations
//     }
//
//     public var isEmpty: Bool {
//         projection == nil
//             && observations.isEmpty
//     }
//
//     public static let none = Self()
// }
