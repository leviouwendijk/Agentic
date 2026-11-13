import Primitives
import Schema

/// The loose form of a call to any capability: an identity and an untyped
/// payload, as received from a model, host, or program.
///
/// It implies no execution authority. Its typed form is
/// `CapabilityRequest<C>`, produced by `CapabilityRequest(parsing:)`.
public struct CapabilityCall: Sendable, Codable, Hashable, Identifiable {
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

    public init(_ call: FunctionCall) {
        self.init(
            id: call.id,
            capability: .tool(ToolIdentifier(call.name)),
            input: call.input
        )
    }
}
