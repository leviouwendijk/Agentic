import Schema

public protocol ToolInput: 
    Sendable 
    & Decodable 
    & JSONSchemaProviding 
{}
    // var repository: String? { get }
// }

// extension ToolInput {
//     var repository: String? {
//         nil
//     }
// }

public protocol ToolOutput: 
    Sendable 
    & Encodable 
{}

// public protocol ToolEnvironment: 
//     Sendable 
// {}

// -------------------------------

public protocol ToolContract: Sendable {
    associatedtype Input: ToolInput
    associatedtype Output: ToolOutput
}
