import Foundation
import Macros
import Primitives
import Schema

/// A function call as it crosses the boundary from a model, CLI, or host,
/// before it is known which capability the name refers to.
///
/// Tool execution never takes this type: `ToolBinding.invocation(for:)`
/// parses it into a `ToolInvocation`, and the runtime resolves non-tool names
/// through the model projection into a `CapabilityCall`.
@JSONSchema
public struct FunctionCall:
    Sendable,
    Codable,
    Hashable,
    Identifiable
{
    public let id: String
    /// The function name as the caller sent it; not yet a capability identity.
    public let name: String
    public let input: JSONValue

    public init(
        id: String,
        name: String,
        input: JSONValue
    ) {
        self.id = id
        self.name = name
        self.input = input
    }

    // The wire key stays `tool` for model-authored plans and CLI input.
    enum CodingKeys: String, CodingKey {
        case id
        case name = "tool"
        case input
    }
}

extension FunctionCall {
    public var reference: ToolExecution.Reference {
        .init(
            id: id,
            tool: ToolIdentifier(name)
        )
    }
}
