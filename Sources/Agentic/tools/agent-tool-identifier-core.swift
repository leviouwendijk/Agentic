public extension AgentToolIdentifier {
    static let clarify_with_user: Self = "clarify_with_user"

    static let compose_context: Self = "compose_context"
    static let inspect_context_sources: Self = "inspect_context_sources"
    static let estimate_context_size: Self = "estimate_context_size"

    static let read_file: Self = "read_file"
    static let write_file: Self = "write_file"
    static let edit_file: Self = "edit_file"
    static let scan_paths: Self = "scan_paths"
    static let read_selection: Self = "read_selection"

    static let inspect_workspace: Self = "inspect_workspace"
    static let list_path_roots: Self = "list_path_roots"
    static let list_path_grants: Self = "list_path_grants"
    static let explain_path_access: Self = "explain_path_access"
    static let find_paths: Self = "find_paths"
    static let request_path_grant: Self = "request_path_grant"

    static let emit_artifact: Self = "emit_artifact"
    static let list_artifacts: Self = "list_artifacts"
    static let read_artifact: Self = "read_artifact"

    static let list_skills: Self = "list_skills"
    static let load_skill: Self = "load_skill"

    static let search_transcript: Self = "search_transcript"
    static let read_transcript_events: Self = "read_transcript_events"
    static let summarize_transcript_window: Self = "summarize_transcript_window"

    static let task_create: Self = "task_create"
    static let task_update: Self = "task_update"
    static let task_list: Self = "task_list"
    static let task_get: Self = "task_get"
    static let task_claim: Self = "task_claim"
    static let task_complete: Self = "task_complete"

    static let list_prepared_intents: Self = "list_prepared_intents"
    static let read_prepared_intent: Self = "read_prepared_intent"
    static let review_prepared_intent: Self = "review_prepared_intent"

    static let list_agent_sessions: Self = "list_agent_sessions"
    static let read_agent_session: Self = "read_agent_session"
    static let read_agent_transcript: Self = "read_agent_transcript"
    static let read_agent_approvals: Self = "read_agent_approvals"
    static let list_agent_artifacts: Self = "list_agent_artifacts"
    static let read_agent_artifact: Self = "read_agent_artifact"
    static let list_agent_prepared_intents: Self = "list_agent_prepared_intents"
    static let read_agent_prepared_intent: Self = "read_agent_prepared_intent"
}
