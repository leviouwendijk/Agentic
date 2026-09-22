import AgenticStandard

func runStandardToolNamespaceSmoke() throws {
    ContractProof.tool(
        Standard.Tools.AgentAdvisor.self
    )
    ContractProof.tool(
        Standard.Tools.EmitArtifact.self
    )
    ContractProof.tool(
        Standard.Tools.ListArtifacts.self
    )
    ContractProof.tool(
        Standard.Tools.ReadArtifact.self
    )
    ContractProof.tool(
        Standard.Tools.FindTools.self
    )

    try ContractProof.identifier(
        Standard.Tools.AgentAdvisor.definition.identifier.rawValue,
        expected: "advisor_ask"
    )
    try ContractProof.identifier(
        Standard.Tools.EmitArtifact.definition.identifier.rawValue,
        expected: "emit_artifact"
    )
    try ContractProof.identifier(
        Standard.Tools.ListArtifacts.definition.identifier.rawValue,
        expected: "list_artifacts"
    )
    try ContractProof.identifier(
        Standard.Tools.ReadArtifact.definition.identifier.rawValue,
        expected: "read_artifact"
    )
    try ContractProof.identifier(
        Standard.Tools.FindTools.definition.identifier.rawValue,
        expected: "find_tools"
    )
}
