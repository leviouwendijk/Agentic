import AgenticStandard
import AgenticTasks

func runStandardToolNamespaceSmoke() throws {
    ContractProof.tool(
        Standard.Tools.AskAdvisor.self
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
        Capabilities.Tools.Search.self
    )
    ContractProof.tool(
        Standard.Tools.SearchGuidelines.self
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
        Standard.Tools.AskAdvisor.Input.self
    )
    ContractProof.result(
        Standard.Tools.AskAdvisor.Output.self
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
        Capabilities.Tools.Search.Input.self
    )
    ContractProof.result(
        Capabilities.Tools.Search.Output.self
    )
    ContractProof.source(
        Standard.Tools.SearchGuidelines.Input.self
    )
    ContractProof.result(
        Standard.Tools.SearchGuidelines.Output.self
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
        Standard.Tools.InspectValues.self
    )
    ContractProof.tool(
        Standard.Tools.ConvertCase.self
    )
    ContractProof.source(
        Standard.Tools.ConvertCase.Input.self
    )
    ContractProof.result(
        Standard.Tools.ConvertCase.Output.self
    )
    ContractProof.source(
        Standard.Tools.InspectValues.Input.self
    )
    ContractProof.result(
        Standard.Tools.InspectValues.Entry.self
    )
    ContractProof.result(
        Standard.Tools.InspectValues.Output.self
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
        Tasks.Tools.CreateTask.self
    )
    ContractProof.source(
        Tasks.Tools.CreateTask.Input.self
    )
    ContractProof.result(
        Tasks.Tools.CreateTask.Output.self
    )
    ContractProof.tool(
        Tasks.Tools.UpdateTask.self
    )
    ContractProof.source(
        Tasks.Tools.UpdateTask.Input.self
    )
    ContractProof.result(
        Tasks.Tools.UpdateTask.Output.self
    )
    ContractProof.tool(
        Tasks.Tools.ListTasks.self
    )
    ContractProof.source(
        Tasks.Tools.ListTasks.Input.self
    )
    ContractProof.result(
        Tasks.Tools.ListTasks.Output.self
    )
    ContractProof.tool(
        Tasks.Tools.GetTask.self
    )
    ContractProof.source(
        Tasks.Tools.GetTask.Input.self
    )
    ContractProof.result(
        Tasks.Tools.GetTask.Output.self
    )
    ContractProof.tool(
        Tasks.Tools.ClaimTask.self
    )
    ContractProof.source(
        Tasks.Tools.ClaimTask.Input.self
    )
    ContractProof.result(
        Tasks.Tools.ClaimTask.Output.self
    )
    ContractProof.tool(
        Tasks.Tools.CompleteTask.self
    )
    ContractProof.source(
        Tasks.Tools.CompleteTask.Input.self
    )
    ContractProof.result(
        Tasks.Tools.CompleteTask.Output.self
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
        Standard.Tools.AskAdvisor.definition.identifier.rawValue,
        expected: "standard_tool_advisor_ask"
    )
    try ContractProof.identifier(
        Standard.Tools.EmitArtifact.definition.identifier.rawValue,
        expected: "standard_tool_emit_artifact"
    )
    try ContractProof.identifier(
        Standard.Tools.ListArtifacts.definition.identifier.rawValue,
        expected: "standard_tool_list_artifacts"
    )
    try ContractProof.identifier(
        Standard.Tools.ReadArtifact.definition.identifier.rawValue,
        expected: "standard_tool_read_artifact"
    )
    try ContractProof.identifier(
        Capabilities.Tools.Search.definition.identifier.rawValue,
        expected: "capabilities_tool_search"
    )
    try ContractProof.identifier(
        Capabilities.Tools.Search.definition.identifier.rawValue,
        expected: "capabilities_tool_search"
    )
    try ContractProof.identifier(
        Capabilities.Tools.Call.definition.identifier.rawValue,
        expected: "capabilities_tool_call"
    )
    try ContractProof.identifier(
        Standard.Tools.SearchGuidelines.definition.identifier.rawValue,
        expected: "standard_tool_search_guidelines"
    )
    try ContractProof.identifier(
        Standard.Tools.GuidelineIndex.definition.identifier.rawValue,
        expected: "standard_tool_guideline_index"
    )
    try ContractProof.identifier(
        Standard.Tools.ReadGuideline.definition.identifier.rawValue,
        expected: "standard_tool_read_guideline"
    )
    try ContractProof.identifier(
        Standard.Tools.ReadGuidelineChapter.definition.identifier.rawValue,
        expected: "standard_tool_read_guideline_chapter"
    )
    try ContractProof.identifier(
        Standard.Tools.InspectValues.definition.identifier.rawValue,
        expected: "standard_tool_inspect_values"
    )
    try ContractProof.identifier(
        Standard.Tools.ConvertCase.definition.identifier.rawValue,
        expected: "standard_tool_convert_case"
    )
    try ContractProof.identifier(
        Standard.Tools.ConvertCase.transform(
            .init(value: "Annual Report", to: .snake)
        ).converted,
        expected: "annual_report"
    )
    try ContractProof.identifier(
        Standard.Tools.ConvertCase.transform(
            .init(value: "Annual Report", to: .kebab)
        ).converted,
        expected: "annual-report"
    )
    try ContractProof.identifier(
        Standard.Tools.ConvertCase.transform(
            .init(value: "already_snake", to: .snake)
        ).converted,
        expected: "already_snake"
    )
    try ContractProof.identifier(
        Standard.Tools.ClarifyWithUser.definition.identifier.rawValue,
        expected: "standard_tool_clarify_with_user"
    )
    try ContractProof.identifier(
        Tasks.Tools.CreateTask.definition.identifier.rawValue,
        expected: "tasks_tool_create"
    )
    try ContractProof.identifier(
        Tasks.Tools.UpdateTask.definition.identifier.rawValue,
        expected: "tasks_tool_update"
    )
    try ContractProof.identifier(
        Tasks.Tools.ListTasks.definition.identifier.rawValue,
        expected: "tasks_tool_list"
    )
    try ContractProof.identifier(
        Tasks.Tools.GetTask.definition.identifier.rawValue,
        expected: "tasks_tool_get"
    )
    try ContractProof.identifier(
        Tasks.Tools.ClaimTask.definition.identifier.rawValue,
        expected: "tasks_tool_claim"
    )
    try ContractProof.identifier(
        Tasks.Tools.CompleteTask.definition.identifier.rawValue,
        expected: "tasks_tool_complete"
    )
    try ContractProof.identifier(
        Standard.Tools.ReadTranscriptEvents.definition.identifier.rawValue,
        expected: "standard_tool_read_transcript_events"
    )
    try ContractProof.identifier(
        Standard.Tools.SearchTranscript.definition.identifier.rawValue,
        expected: "standard_tool_search_transcript"
    )
    try ContractProof.identifier(
        Standard.Tools.SummarizeTranscriptWindow.definition.identifier.rawValue,
        expected: "standard_tool_summarize_transcript_window"
    )
}