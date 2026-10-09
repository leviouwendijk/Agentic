import Primitives
import Schema

/// A type-resolved Agent declaration, retaining its authored input contract.
/// Launch, looping, child identity, approvals and suspension belong to Runtime.
public struct AgentBinding: CapabilityBinding {
    public let definition: AgentDefinition
    public let capabilityContract: CapabilityContract

    private let validateInputHandler: @Sendable (JSONValue) throws -> Void

    public init<A: Agent>(_ agent: A.Type) {
        self.definition = A.definition
        self.capabilityContract = A.contract
        self.validateInputHandler = { input in
            _ = try JSONCoding.default.decode(A.Input.self, from: input)
        }
    }

    public var reference: CapabilityReference {
        .agent(definition.identifier)
    }

    /// Preserve the call ID and payload, but only after kind, identity and
    /// the authored Input schema have been verified.
    public func call(from raw: CapabilityCall.Raw) throws -> AgentCall {
        guard raw.capability == reference else {
            throw CapabilityRequestError.mismatchedCapability(
                expected: reference,
                actual: raw.capability
            )
        }
        try validateInputHandler(raw.input)
        return AgentCall(
            id: raw.id,
            agent: definition.identifier,
            input: raw.input
        )
    }
}
