import Primitives
import Schema

public enum CapabilityRequestError: Error, Sendable, Equatable {
    case mismatchedCapability(
        expected: CapabilityReference,
        actual: CapabilityReference
    )
}

/// Semantic input whose concrete C.Input type is known. It is not an
/// authorization, execution, or assertion that C is installed.
public struct CapabilityRequest<C: Capability>: Sendable {
    public let input: C.Input

    public init(_ input: C.Input) {
        self.input = input
    }

    /// Verify kind and identity before decoding the untrusted input payload.
    public init(parsing raw: CapabilityCall.Raw) throws {
        guard raw.capability == C.reference else {
            throw CapabilityRequestError.mismatchedCapability(
                expected: C.reference,
                actual: raw.capability
            )
        }
        self.input = try JSONCoding.default.decode(
            C.Input.self,
            from: raw.input
        )
    }
}

public extension Capability {
    typealias Request = CapabilityRequest<Self>
}
