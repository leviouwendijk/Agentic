// MOVE: AgenticExecution — stdout, stderr, diagnostics, logs, and detail
// are execution observations/telemetry rather than semantic Tool result state.
// The old declaration is intentionally left commented until the execution move lands.
//
// public struct AgentToolResultObservation:
//     Sendable,
//     Codable,
//     Hashable
// {
//     public let kind: Kind
//     public let label: String?
//     public let content: String
//
//     public init(
//         kind: Kind,
//         label: String? = nil,
//         content: String
//     ) {
//         self.kind = kind
//         self.label = label
//         self.content = content
//     }
//
//     public enum Kind:
//         String,
//         Sendable,
//         Codable,
//         Hashable,
//         CaseIterable
//     {
//         case standard_output
//         case standard_error
//         case diagnostic
//         case log
//         case detail
//     }
// }
