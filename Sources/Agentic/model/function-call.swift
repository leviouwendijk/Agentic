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
    /// Identity of one function call without its payload.
    @JSONSchema
    public struct Reference:
        Sendable,
        Codable,
        Hashable,
        Identifiable
    {
        /// The call identifier.
        public let id: String
        /// The function name the call used.
        public let name: String

        public init(
            id: String,
            name: String
        ) {
            self.id = id
            self.name = name
        }

        /// The boundary identity of a call the tool engine executed.
        public init(
            _ reference: ToolExecution.Reference
        ) {
            self.init(
                id: reference.id,
                name: reference.tool.rawValue
            )
        }

        enum CodingKeys: String, CodingKey {
            case id
            case name = "tool"
        }
    }

    /// What the caller, and the model, receives in reply to one function call,
    /// whichever capability answered it.
    @JSONSchema
    public struct Response:
        Sendable,
        Codable,
        Hashable
    {
        /// The call this responds to.
        public let call: Reference
        /// The encoded output.
        public let output: JSONValue
        /// Optional compact summary of the output.
        public let projection: ToolExecution.Projection?
        /// Whether the output reports a failure.
        public let isError: Bool

        public init(
            call: Reference,
            output: JSONValue,
            projection: ToolExecution.Projection? = nil,
            isError: Bool = false
        ) {
            self.call = call
            self.output = output
            self.projection = projection
            self.isError = isError
        }
    }

    public var reference: Reference {
        .init(
            id: id,
            name: name
        )
    }
}
