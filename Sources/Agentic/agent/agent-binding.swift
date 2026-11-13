import Primitives
import Schema

/// A type-resolved Agent declaration, retaining its authored input contract.
/// Launch, looping, child identity, approvals and suspension belong to Runtime.
public struct AgentBinding: CapabilityBinding {
    public let definition: AgentDefinition
    public let contract: CapabilityContract

    private let validateInputHandler: @Sendable (JSONValue) throws -> Void

    public init<A: Agent>(_ agent: A.Type) {
        self.definition = A.definition
        self.contract = A.contract
        self.validateInputHandler = { input in
            _ = try JSONCoding.default.decode(A.Input.self, from: input)
        }
    }

    public var reference: CapabilityReference {
        .agent(definition.identifier)
    }

    /// Returns the call unchanged once kind, identity and the authored Input
    /// schema have been verified.
    public func verify(_ call: CapabilityCall) throws -> CapabilityCall {
        guard call.capability == reference else {
            throw CapabilityRequestError.mismatchedCapability(
                expected: reference,
                actual: call.capability
            )
        }
        try validateInputHandler(call.input)
        return call
    }
}
