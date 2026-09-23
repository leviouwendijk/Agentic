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
    ContractProof.tool(
        Standard.Tools.ClarifyWithUser.self
    )
    ContractProof.source(
        Standard.Tools.ClarifyWithUser.Input.self
    )
    ContractProof.result(
        Standard.Tools.ClarifyWithUser.Output.self
    )
    ContractProof.tool(
        Standard.Tools.ListSkills.self
    )
    ContractProof.source(
        Standard.Tools.ListSkills.Input.self
    )
    ContractProof.result(
        Standard.Tools.ListSkills.Output.self
    )
    ContractProof.tool(
        Standard.Tools.LoadSkill.self
    )
    ContractProof.source(
        Standard.Tools.LoadSkill.Input.self
    )
    ContractProof.result(
        Standard.Tools.LoadSkill.Output.self
    )
    ContractProof.tool(
        Standard.Tools.CreateAgentTask.self
    )
    ContractProof.source(
        Standard.Tools.CreateAgentTask.Input.self
    )
    ContractProof.result(
        Standard.Tools.CreateAgentTask.Output.self
    )
    ContractProof.tool(
        Standard.Tools.UpdateAgentTask.self
    )
    ContractProof.source(
        Standard.Tools.UpdateAgentTask.Input.self
    )
    ContractProof.result(
        Standard.Tools.UpdateAgentTask.Output.self
    )
    ContractProof.tool(
        Standard.Tools.ListAgentTasks.self
    )
    ContractProof.source(
        Standard.Tools.ListAgentTasks.Input.self
    )
    ContractProof.result(
        Standard.Tools.ListAgentTasks.Output.self
    )
    ContractProof.tool(
        Standard.Tools.GetAgentTask.self
    )
    ContractProof.source(
        Standard.Tools.GetAgentTask.Input.self
    )
    ContractProof.result(
        Standard.Tools.GetAgentTask.Output.self
    )
    ContractProof.tool(
        Standard.Tools.ClaimAgentTask.self
    )
    ContractProof.source(
        Standard.Tools.ClaimAgentTask.Input.self
    )
    ContractProof.result(
        Standard.Tools.ClaimAgentTask.Output.self
    )
    ContractProof.tool(
        Standard.Tools.CompleteAgentTask.self
    )
    ContractProof.source(
        Standard.Tools.CompleteAgentTask.Input.self
    )
    ContractProof.result(
        Standard.Tools.CompleteAgentTask.Output.self
    )
    ContractProof.tool(
        Standard.Tools.ReadTranscriptEvents.self
    )
    ContractProof.source(
        Standard.Tools.ReadTranscriptEvents.Input.self
    )
    ContractProof.result(
        Standard.Tools.ReadTranscriptEvents.Output.self
    )
    ContractProof.tool(
        Standard.Tools.SearchTranscript.self
    )
    ContractProof.source(
        Standard.Tools.SearchTranscript.Input.self
    )
    ContractProof.result(
        Standard.Tools.SearchTranscript.Output.self
    )
    ContractProof.tool(
        Standard.Tools.SummarizeTranscriptWindow.self
    )
    ContractProof.source(
        Standard.Tools.SummarizeTranscriptWindow.Input.self
    )
    ContractProof.result(
        Standard.Tools.SummarizeTranscriptWindow.Output.self
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
    try ContractProof.identifier(
        Standard.Tools.ClarifyWithUser.definition.identifier.rawValue,
        expected: "clarify_with_user"
    )
    try ContractProof.identifier(
        Standard.Tools.ListSkills.definition.identifier.rawValue,
        expected: "list_skills"
    )
    try ContractProof.identifier(
        Standard.Tools.LoadSkill.definition.identifier.rawValue,
        expected: "load_skill"
    )
    try ContractProof.identifier(
        Standard.Tools.CreateAgentTask.definition.identifier.rawValue,
        expected: "task_create"
    )
    try ContractProof.identifier(
        Standard.Tools.UpdateAgentTask.definition.identifier.rawValue,
        expected: "task_update"
    )
    try ContractProof.identifier(
        Standard.Tools.ListAgentTasks.definition.identifier.rawValue,
        expected: "task_list"
    )
    try ContractProof.identifier(
        Standard.Tools.GetAgentTask.definition.identifier.rawValue,
        expected: "task_get"
    )
    try ContractProof.identifier(
        Standard.Tools.ClaimAgentTask.definition.identifier.rawValue,
        expected: "task_claim"
    )
    try ContractProof.identifier(
        Standard.Tools.CompleteAgentTask.definition.identifier.rawValue,
        expected: "task_complete"
    )
    try ContractProof.identifier(
        Standard.Tools.ReadTranscriptEvents.definition.identifier.rawValue,
        expected: "read_transcript_events"
    )
    try ContractProof.identifier(
        Standard.Tools.SearchTranscript.definition.identifier.rawValue,
        expected: "search_transcript"
    )
    try ContractProof.identifier(
        Standard.Tools.SummarizeTranscriptWindow.definition.identifier.rawValue,
        expected: "summarize_transcript_window"
    )
}
