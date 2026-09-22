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
    ContractProof.tool(
        Standard.Tools.FindGuidelines.self
    )
    ContractProof.tool(
        Standard.Tools.GuidelineIndex.self
    )
    ContractProof.tool(
        Standard.Tools.ReadGuideline.self
    )
    ContractProof.tool(
        Standard.Tools.ReadGuidelineChapter.self
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
    try ContractProof.identifier(
        Standard.Tools.FindGuidelines.definition.identifier.rawValue,
        expected: "find_guidelines"
    )
    try ContractProof.identifier(
        Standard.Tools.GuidelineIndex.definition.identifier.rawValue,
        expected: "guideline_index"
    )
    try ContractProof.identifier(
        Standard.Tools.ReadGuideline.definition.identifier.rawValue,
        expected: "read_guideline"
    )
    try ContractProof.identifier(
        Standard.Tools.ReadGuidelineChapter.definition.identifier.rawValue,
        expected: "read_guideline_chapter"
    )
}
