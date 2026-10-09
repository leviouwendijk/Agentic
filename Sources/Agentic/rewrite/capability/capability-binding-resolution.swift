/// Typed family resolution at the inventory boundary; unlike a descriptor,
/// a returned binding retains executable handlers and their typed contract.
public extension ToolRegistry {
    func binding(for reference: CapabilityReference) throws -> ToolBinding {
        guard case let .tool(identifier) = reference else {
            throw CapabilityResolutionError.incompatibleReference(reference)
        }
        guard let binding = registeredTool(identifiedBy: identifier) else {
            throw CapabilityResolutionError.notInstalled(reference)
        }
        return binding
    }
}

public extension ProgramRegistry {
    func binding(for reference: CapabilityReference) throws -> ProgramBinding {
        guard case let .program(identifier) = reference else {
            throw CapabilityResolutionError.incompatibleReference(reference)
        }
        guard let binding = registeredProgram(identifiedBy: identifier) else {
            throw CapabilityResolutionError.notInstalled(reference)
        }
        return binding
    }
}
