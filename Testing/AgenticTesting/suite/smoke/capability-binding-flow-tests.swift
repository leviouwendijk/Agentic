import Agentic
import Testing

private enum BindingTestFailure: Error {
    case unexpectedResolution
}

func runCapabilityBindingSmoke() throws {
    var tools = ToolRegistry()
    try tools.register(SmokeTool())

    let toolReference = SmokeTool.reference
    let tool = try tools.binding(for: toolReference)
    try Expect.equal(tool.reference, toolReference, "tool binding preserves identity")
    try Expect.equal(
        tool.capabilityContract.input,
        SmokeTool.contract.input,
        "tool binding retains typed semantic input schema"
    )

    let hostOnly = ToolBinding(SmokeTool(), modelContract: .hostOnly)
    try Expect.equal(hostOnly.isModelFacing, false, "host-only remains executable without model projection")
    try Expect.equal(hostOnly.reference, toolReference, "host-only binding retains identity")

    do {
        _ = try tools.binding(for: .program(.init(rawValue: tool.definition.identifier.rawValue)))
        throw BindingTestFailure.unexpectedResolution
    } catch let error as CapabilityResolutionError {
        guard case .incompatibleReference = error else {
            throw BindingTestFailure.unexpectedResolution
        }
    }

    let absent: CapabilityReference = .tool(.init(rawValue: "absent_tool"))
    do {
        _ = try tools.binding(for: absent)
        throw BindingTestFailure.unexpectedResolution
    } catch let error as CapabilityResolutionError {
        guard case let .notInstalled(reference) = error else {
            throw BindingTestFailure.unexpectedResolution
        }
        try Expect.equal(reference, absent, "missing binding preserves requested identity")
    }

    var programs = ProgramRegistry()
    try programs.register(SmokeDomain.Programs.MacroSmokeProgram())
    let programReference = SmokeDomain.Programs.MacroSmokeProgram.reference
    let program = try programs.binding(for: programReference)
    try Expect.equal(program.reference, programReference, "program binding preserves identity")
    try Expect.equal(
        program.capabilityContract.output,
        SmokeDomain.Programs.MacroSmokeProgram.contract.output,
        "program binding retains semantic output schema"
    )
}
