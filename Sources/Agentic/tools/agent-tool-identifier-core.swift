import Macros

@StringIdentifiers
public extension ToolIdentifier {
    static var clarify_with_user: Self

    static var compose_context: Self
    static var inspect_context_sources: Self
    static var estimate_context_size: Self

    static var read_file: Self
    static var mutate_files: Self
    static var scan_paths: Self
    static var read_selection: Self

    static var inspect_workspace: Self
    static var list_path_roots: Self
    static var list_path_grants: Self
    static var explain_path_access: Self
    static var find_paths: Self
    static var request_path_grant: Self

    static var emit_artifact: Self
    static var list_artifacts: Self
    static var read_artifact: Self

    static var list_skills: Self
    static var load_skill: Self

    static var search_transcript: Self
    static var read_transcript_events: Self
    static var summarize_transcript_window: Self

    static var task_create: Self
    static var task_update: Self
    static var task_list: Self
    static var task_get: Self
    static var task_claim: Self
    static var task_complete: Self

    static var list_prepared_intents: Self
    static var read_prepared_intent: Self
    static var review_prepared_intent: Self

    static var list_agent_sessions: Self
    static var read_agent_session: Self
    static var read_agent_transcript: Self
    static var read_agent_approvals: Self
    static var list_agent_artifacts: Self
    static var read_agent_artifact: Self
    static var list_agent_prepared_intents: Self
    static var read_agent_prepared_intent: Self

    static var execute_prepared_intent: Self

    static var list_file_mutations: Self
    static var inspect_file_mutation: Self

    static var rollback_file_mutation: Self
}
