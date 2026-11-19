import Agentic
import Macros
import Primitives
import Schema

public enum CallCapabilityError: Error, Sendable, CustomStringConvertible {
    case notRevealed(String)
    case direct(String)

    public var description: String {
        switch self {
        case .notRevealed(let identifier):
            "'\(identifier)' is not available to call: find it with list_capabilities or search_capabilities, then read its contract with inspect_capability."
        case .direct(let identifier):
            "'\(identifier)' is in your tool definitions: call it by its own name."
        }
    }
}

public extension Standard.Tools {
    /// Calls a capability revealed during the session. The provider's tool
    /// definitions stay as the session opened, because any change to them
    /// rewrites the whole cached prompt; capabilities revealed later are
    /// called through this one definition instead. The runtime turns the
    /// call into a call of the capability itself, under its own approval,
    /// preflight and record, so this tool only runs when that fails.
    @Tool
    struct CallCapability: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            /// The capability, as inspect_capability named it.
            public let identifier: String
            /// Its input, as its contract describes.
            public let input: JSONValue

            public init(identifier: String, input: JSONValue) {
                self.identifier = identifier
                self.input = input
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let identifier: String

            public init(identifier: String) {
                self.identifier = identifier
            }
        }

        public static let purpose =
            "Call a capability revealed by inspect_capability during this session, with its identifier and its input as the contract describes; call tools in your definitions by their own names."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            if let visible = await context.capabilities?.snapshot().visible,
               visible.tools.contains(ToolIdentifier(input.identifier)) {
                throw CallCapabilityError.direct(input.identifier)
            }
            throw CallCapabilityError.notRevealed(input.identifier)
        }
    }
}
