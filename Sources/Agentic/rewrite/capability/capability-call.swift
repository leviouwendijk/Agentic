import Primitives
import Schema

/// A transport-boundary call, before capability resolution or typed decoding.
/// No execution authority is implied by the presence of a reference.
public enum CapabilityCall {
    public struct Raw: Sendable, Codable {
        public let id: String
        public let capability: CapabilityReference
        public let input: JSONValue

        public init(
            id: String,
            capability: CapabilityReference,
            input: JSONValue
        ) {
            self.id = id
            self.capability = capability
            self.input = input
        }

        public init(_ call: ToolCall) {
            self.init(
                id: call.id,
                capability: .tool(call.tool),
                input: call.input
            )
        }

        public init(_ call: AgentCall) {
            self.init(
                id: call.id,
                capability: .agent(call.agent),
                input: call.input
            )
        }
    }
}
