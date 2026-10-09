/// A kind-qualified identity. This value does not establish installation,
/// enablement, exposure, or an executable implementation.
public enum CapabilityReference: Sendable, Codable, Hashable {
    case tool(ToolIdentifier)
    case program(ProgramIdentifier)
    case inference(InferenceIdentifier)
    case agent(AgentIdentifier)
}

public extension Tool {
    static var reference: CapabilityReference {
        .tool(definition.identifier)
    }
}

public extension Program {
    static var reference: CapabilityReference {
        .program(definition.identifier)
    }
}

public extension Inference {
    static var reference: CapabilityReference {
        .inference(definition.identifier)
    }
}

public extension Agent {
    static var reference: CapabilityReference {
        .agent(definition.identifier)
    }
}
