// MIGRATED: ToolCall now owns the call envelope and its lifecycle vocabulary.
// This former parallel call type is intentionally left commented for migration history.
// Do not reintroduce a second semantic tool-call representation.
//
// import Primitives
//
// public struct AgentToolCall: Sendable, Codable, Hashable, Identifiable {
//     public let id: String
//     public let name: String
//     public let input: JSONValue
//
//     public init(
//         id: String,
//         name: String,
//         input: JSONValue
//     ) {
//         self.id = id
//         self.name = name
//         self.input = input
//     }
// }
