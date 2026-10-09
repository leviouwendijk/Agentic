/// An implementation resolved at its family's executable boundary.
/// Binding by itself does not grant authorization or model exposure.
public protocol CapabilityBinding: Sendable {
    var reference: CapabilityReference { get }
    var capabilityContract: CapabilityContract { get }
}

public enum CapabilityResolutionError: Error, Sendable, Equatable {
    case incompatibleReference(CapabilityReference)
    case notInstalled(CapabilityReference)
}
