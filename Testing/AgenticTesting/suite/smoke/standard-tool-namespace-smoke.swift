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

    ContractProof.source(
        Standard.Tools.AgentAdvisor.Input.self
    )
    ContractProof.result(
        Standard.Tools.AgentAdvisor.Output.self
    )
    ContractProof.source(
        Standard.Tools.EmitArtifact.Input.self
    )
    ContractProof.result(
        Standard.Tools.EmitArtifact.Output.self
    )
    ContractProof.source(
        Standard.Tools.ListArtifacts.Input.self
    )
    ContractProof.result(
        Standard.Tools.ListArtifacts.Output.self
    )
    ContractProof.source(
        Standard.Tools.ReadArtifact.Input.self
    )
    ContractProof.result(
        Standard.Tools.ReadArtifact.Output.self
    )
    ContractProof.source(
        Standard.Tools.FindTools.Input.self
    )
    ContractProof.result(
        Standard.Tools.FindTools.Output.self
    )
    ContractProof.source(
        Standard.Tools.FindGuidelines.Input.self
    )
    ContractProof.result(
        Standard.Tools.FindGuidelines.Output.self
    )
    ContractProof.source(
        Standard.Tools.GuidelineIndex.Input.self
    )
    ContractProof.result(
        Standard.Tools.GuidelineIndex.Output.self
    )
    ContractProof.source(
        Standard.Tools.ReadGuideline.Input.self
    )
    ContractProof.result(
        Standard.Tools.ReadGuideline.Output.self
    )
    ContractProof.source(
        Standard.Tools.ReadGuidelineChapter.Input.self
    )
    ContractProof.result(
        Standard.Tools.ReadGuidelineChapter.Output.self
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
