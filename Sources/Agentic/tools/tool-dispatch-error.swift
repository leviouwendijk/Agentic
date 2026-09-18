// MOVE: AgenticExecution — unknown-tool dispatch is registry/execution behavior,
// not part of the semantic Tool declaration contract.
// The old declaration is intentionally left commented until that move lands.
//
// import Foundation
//
// public enum ToolDispatchError: Error, Sendable, LocalizedError {
//     case unknownTool(String)
//
//     public var errorDescription: String? {
//         switch self {
//         case .unknownTool(let name):
//             return "Unknown tool: \(name)"
//         }
//     }
// }
