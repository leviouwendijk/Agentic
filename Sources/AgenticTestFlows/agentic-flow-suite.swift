import TestFlows

enum AgenticFlowSuite: TestFlowRegistry {
    static let title = "Agentic flow tests"

    static let flows: [TestFlow] = [
        TestFlow(
            ID.buffered,
            tags: ["agentic", "buffered"]
        ) {
            try await AgenticFlowTesting.runBuffered()
        },

        TestFlow(
            ID.stream,
            tags: ["agentic", "stream"]
        ) {
            try await AgenticFlowTesting.runStream()
        },

        TestFlow(
            ID.stream_error,
            tags: ["agentic", "stream", "error"]
        ) {
            try await AgenticFlowTesting.runStreamError()
        },

        TestFlow(
            ID.stream_cancel,
            tags: ["agentic", "stream", "cancel"]
        ) {
            try await AgenticFlowTesting.runStreamCancel()
        },

        TestFlow(
            ID.stream_tool_use,
            tags: ["agentic", "stream", "tool-use"]
        ) {
            try await AgenticFlowTesting.runStreamToolUse()
        },

        TestFlow(
            ID.file_mutation_store,
            tags: ["agentic", "mutation", "store"]
        ) {
            try await AgenticFlowTesting.runFileMutationStore()
        },

        TestFlow(
            ID.file_editor_recorded_write,
            tags: ["agentic", "mutation", "editor", "write"]
        ) {
            try await AgenticFlowTesting.runFileEditorRecordedWrite()
        },

        TestFlow(
            ID.file_editor_recorded_edit,
            tags: ["agentic", "mutation", "editor", "edit"]
        ) {
            try await AgenticFlowTesting.runFileEditorRecordedEdit()
        },

        TestFlow(
            ID.file_tool_recorded_write,
            tags: ["agentic", "mutation", "tool", "write"]
        ) {
            try await AgenticFlowTesting.runFileToolRecordedWrite()
        },

        TestFlow(
            ID.file_tool_recorded_edit,
            tags: ["agentic", "mutation", "tool", "edit"]
        ) {
            try await AgenticFlowTesting.runFileToolRecordedEdit()
        },

        TestFlow(
            ID.no_local_backup_default,
            tags: ["agentic", "mutation", "backup"]
        ) {
            try await AgenticFlowTesting.runNoLocalBackupDefault()
        },

        TestFlow(
            ID.file_mutation_diff_artifact,
            tags: ["agentic", "mutation", "artifact", "diff"]
        ) {
            try await AgenticFlowTesting.runFileMutationDiffArtifact()
        },

        TestFlow(
            ID.dsl_typed_call,
            tags: ["agentic", "dsl", "tool", "call"]
        ) {
            try await AgenticFlowTesting.runDSLTypedCall()
        },

        TestFlow(
            ID.dsl_contextual_typed_call,
            tags: ["agentic", "dsl", "tool", "context"]
        ) {
            try await AgenticFlowTesting.runDSLContextualTypedCall()
        },

        TestFlow(
            ID.dsl_effect_call,
            tags: ["agentic", "dsl", "tool", "effect"]
        ) {
            try await AgenticFlowTesting.runDSLEffectCall()
        },

        TestFlow(
            ID.dsl_missing_call,
            tags: ["agentic", "dsl", "tool", "error"]
        ) {
            try await AgenticFlowTesting.runDSLMissingCallThrows()
        },

        TestFlow(
            ID.dsl_registry_mixed_inputs,
            tags: ["agentic", "dsl", "registry"]
        ) {
            try await AgenticFlowTesting.runDSLRegistryAcceptsMixedInputs()
        },

        TestFlow(
            ID.core_tool_set_builder_registration,
            tags: ["agentic", "dsl", "registry", "core-tools"]
        ) {
            try await AgenticFlowTesting.runCoreToolSetBuilderRegistration()
        },

        TestFlow(
            ID.file_mutation_preflight_write,
            tags: ["agentic", "mutation", "preflight", "write"]
        ) {
            try await AgenticFlowTesting.runFileMutationPreflightWrite()
        },

        TestFlow(
            ID.file_mutation_preflight_edit,
            tags: ["agentic", "mutation", "preflight", "edit"]
        ) {
            try await AgenticFlowTesting.runFileMutationPreflightEdit()
        },

        TestFlow(
            ID.file_mutation_preflight_no_side_effects,
            tags: ["agentic", "mutation", "preflight", "side-effects"]
        ) {
            try await AgenticFlowTesting.runFileMutationPreflightNoSideEffects()
        },

        TestFlow(
            ID.prepared_file_mutation_write,
            tags: ["agentic", "mutation", "prepared-intent", "write"]
        ) {
            try await AgenticFlowTesting.runPreparedFileMutationWrite()
        },

        TestFlow(
            ID.prepared_file_mutation_edit,
            tags: ["agentic", "mutation", "prepared-intent", "edit"]
        ) {
            try await AgenticFlowTesting.runPreparedFileMutationEdit()
        },

        TestFlow(
            ID.execute_prepared_intent_replays_file_mutation_write,
            tags: ["agentic", "mutation", "prepared-intent", "execute", "write", "registry"]
        ) {
            try await AgenticFlowTesting.runExecutePreparedIntentReplaysFileMutationWrite()
        },

        TestFlow(
            ID.execute_prepared_intent_replays_file_mutation_edit,
            tags: ["agentic", "mutation", "prepared-intent", "execute", "edit", "registry"]
        ) {
            try await AgenticFlowTesting.runExecutePreparedIntentReplaysFileMutationEdit()
        },

        TestFlow(
            ID.execute_prepared_intent_requires_approved,
            tags: ["agentic", "mutation", "prepared-intent", "execute", "approval", "registry"]
        ) {
            try await AgenticFlowTesting.runExecutePreparedIntentRequiresApproved()
        },

        TestFlow(
            ID.execute_prepared_intent_rejects_missing_execution_tool,
            tags: ["agentic", "mutation", "prepared-intent", "execute", "error", "registry"]
        ) {
            try await AgenticFlowTesting.runExecutePreparedIntentRejectsMissingExecutionTool()
        },

        TestFlow(
            ID.prepared_intent_operator_tool_set_registers_execute_when_execution_registry_provided,
            tags: ["agentic", "prepared-intent", "tool-set", "registry"]
        ) {
            try await AgenticFlowTesting.runPreparedIntentOperatorToolSetRegistersExecuteWhenExecutionRegistryProvided()
        },

        TestFlow(
            ID.list_file_mutations_tool,
            tags: ["agentic", "mutation", "history", "tool", "list"]
        ) {
            try await AgenticFlowTesting.runListFileMutationsTool()
        },

        TestFlow(
            ID.inspect_file_mutation_tool,
            tags: ["agentic", "mutation", "history", "tool", "inspect"]
        ) {
            try await AgenticFlowTesting.runInspectFileMutationTool()
        },

        TestFlow(
            ID.inspect_file_mutation_loads_diff_artifact,
            tags: ["agentic", "mutation", "history", "artifact", "diff"]
        ) {
            try await AgenticFlowTesting.runInspectFileMutationLoadsDiffArtifact()
        },

        TestFlow(
            ID.inspect_file_mutation_rejects_missing_id,
            tags: ["agentic", "mutation", "history", "error"]
        ) {
            try await AgenticFlowTesting.runInspectFileMutationRejectsMissingID()
        },

        TestFlow(
            ID.file_mutation_rollback_preflight,
            tags: ["agentic", "mutation", "rollback", "preflight"]
        ) {
            try await AgenticFlowTesting.runFileMutationRollbackPreflight()
        },

        TestFlow(
            ID.file_mutation_rollback_preflight_rejects_missing_id,
            tags: ["agentic", "mutation", "rollback", "preflight", "error"]
        ) {
            try await AgenticFlowTesting.runFileMutationRollbackPreflightRejectsMissingID()
        },

        TestFlow(
            ID.prepared_file_mutation_rollback,
            tags: ["agentic", "mutation", "rollback", "prepared-intent"]
        ) {
            try await AgenticFlowTesting.runPreparedFileMutationRollback()
        },

        TestFlow(
            ID.execute_prepared_intent_replays_file_mutation_rollback,
            tags: ["agentic", "mutation", "rollback", "prepared-intent", "execute", "registry"]
        ) {
            try await AgenticFlowTesting.runExecutePreparedIntentReplaysFileMutationRollback()
        },

        TestFlow(
            ID.execute_prepared_intent_rollback_records_mutation,
            tags: ["agentic", "mutation", "rollback", "prepared-intent", "execute", "record", "registry"]
        ) {
            try await AgenticFlowTesting.runExecutePreparedIntentRollbackRecordsMutation()
        },

        TestFlow(
            ID.execute_prepared_intent_rejects_stale_file_mutation_write,
            tags: ["agentic", "mutation", "prepared-intent", "execute", "drift", "write"]
        ) {
            try await AgenticFlowTesting.runExecutePreparedIntentRejectsStaleFileMutationWrite()
        },

        TestFlow(
            ID.execute_prepared_intent_rejects_stale_file_mutation_edit,
            tags: ["agentic", "mutation", "prepared-intent", "execute", "drift", "edit"]
        ) {
            try await AgenticFlowTesting.runExecutePreparedIntentRejectsStaleFileMutationEdit()
        },

        TestFlow(
            ID.tool_use_batch_observe,
            tags: ["agentic", "tool-use", "batch"]
        ) {
            try await AgenticFlowTesting.runToolUseBatchObserve()
        },

        TestFlow(
            ID.tool_use_batch_approval_skip,
            tags: ["agentic", "tool-use", "batch", "approval"]
        ) {
            try await AgenticFlowTesting.runToolUseBatchApprovalSkip()
        },

        TestFlow(
            ID.tool_use_batch_denial_skip,
            tags: ["agentic", "tool-use", "batch", "approval", "denial"]
        ) {
            try await AgenticFlowTesting.runToolUseBatchDenialSkip()
        },

        TestFlow(
            ID.model_route_planner_prefers_default,
            tags: ["agentic", "model-routing"]
        ) {
            try await AgenticFlowTesting.runModelRoutePlannerPrefersDefault()
        },

        TestFlow(
            ID.model_route_researcher_prefers_default,
            tags: ["agentic", "model-routing"]
        ) {
            try await AgenticFlowTesting.runModelRouteResearcherPrefersDefault()
        },

        TestFlow(
            ID.model_route_researcher_selects_nova_pro_candidate,
            tags: ["agentic", "model-routing"]
        ) {
            try await AgenticFlowTesting.runModelRouteResearcherSelectsNovaProCandidate()
        },

        TestFlow(
            ID.model_route_purpose_codable_roundtrip,
            tags: ["agentic", "model-routing"]
        ) {
            try await AgenticFlowTesting.runModelRoutePurposeCodableRoundTrip()
        },

        TestFlow(
            ID.model_id_known_models_codable_roundtrip,
            tags: ["agentic", "model-routing", "model-id"]
        ) {
            try await AgenticFlowTesting.runModelIDKnownModelsCodableRoundTrip()
        },

        TestFlow(
            ID.model_route_preferred_model_id,
            tags: ["agentic", "model-routing", "model-id"]
        ) {
            try await AgenticFlowTesting.runModelRoutePreferredModelID()
        },

        TestFlow(
            ID.mode_catalog_registers_default_modes,
            tags: ["agentic", "mode", "catalog"]
        ) {
            try await AgenticFlowTesting.runModeCatalogRegistersDefaultModes()
        },

        TestFlow(
            ID.mode_planning_selects_planner_purpose,
            tags: ["agentic", "mode", "routing"]
        ) {
            try await AgenticFlowTesting.runModePlanningSelectsPlannerPurpose()
        },

        TestFlow(
            ID.mode_research_selects_researcher_purpose,
            tags: ["agentic", "mode", "routing"]
        ) {
            try await AgenticFlowTesting.runModeResearchSelectsResearcherPurpose()
        },

        TestFlow(
            ID.mode_coder_exposes_file_mutation_tools,
            tags: ["agentic", "mode", "tools"]
        ) {
            try await AgenticFlowTesting.runModeCoderExposesFileMutationTools()
        },

        TestFlow(
            ID.mode_review_hides_mutation_tools,
            tags: ["agentic", "mode", "tools"]
        ) {
            try await AgenticFlowTesting.runModeReviewHidesMutationTools()
        },

        TestFlow(
            ID.mode_private_requires_local_private_policy,
            tags: ["agentic", "mode", "privacy"]
        ) {
            try await AgenticFlowTesting.runModePrivateRequiresLocalPrivatePolicy()
        },

        TestFlow(
            ID.mode_selection_codable_roundtrip,
            tags: ["agentic", "mode", "codable"]
        ) {
            try await AgenticFlowTesting.runModeSelectionCodableRoundTrip()
        },

        TestFlow(
            ID.mode_application_filters_coder_tools,
            tags: ["agentic", "mode", "application"]
        ) {
            try await AgenticFlowTesting.runModeApplicationFiltersCoderTools()
        },

        TestFlow(
            ID.mode_application_rejects_missing_tool,
            tags: ["agentic", "mode", "application"]
        ) {
            try await AgenticFlowTesting.runModeApplicationRejectsMissingTool()
        },

        TestFlow(
            ID.mode_application_reports_missing_skills,
            tags: ["agentic", "mode", "application"]
        ) {
            try await AgenticFlowTesting.runModeApplicationReportsMissingSkills()
        },

        TestFlow(
            ID.mode_application_loads_available_skills,
            tags: ["agentic", "mode", "application"]
        ) {
            try await AgenticFlowTesting.runModeApplicationLoadsAvailableSkills()
        },
    ]

    enum ID {
        static let buffered = "buffered"
        static let stream = "stream"
        static let stream_error = "stream-error"
        static let stream_cancel = "stream-cancel"
        static let stream_tool_use = "stream-tool-use"

        static let file_mutation_store = "file-mutation-store"
        static let file_editor_recorded_write = "file-editor-recorded-write"
        static let file_editor_recorded_edit = "file-editor-recorded-edit"
        static let file_tool_recorded_write = "file-tool-recorded-write"
        static let file_tool_recorded_edit = "file-tool-recorded-edit"
        static let no_local_backup_default = "no-local-backup-default"
        static let file_mutation_diff_artifact = "file-mutation-diff-artifact"

        static let dsl_typed_call = "dsl-typed-call"
        static let dsl_contextual_typed_call = "dsl-contextual-typed-call"
        static let dsl_effect_call = "dsl-effect-call"
        static let dsl_missing_call = "dsl-missing-call"
        static let dsl_registry_mixed_inputs = "dsl-registry-mixed-inputs"

        static let core_tool_set_builder_registration = "core-tool-set-builder-registration"
        static let tool_registry_executes_with_context = "tool-registry-executes-with-context"

        static let file_mutation_preflight_write = "file-mutation-preflight-write"
        static let file_mutation_preflight_edit = "file-mutation-preflight-edit"
        static let file_mutation_preflight_no_side_effects = "file-mutation-preflight-no-side-effects"
        static let prepared_file_mutation_write = "prepared-file-mutation-write"
        static let prepared_file_mutation_edit = "prepared-file-mutation-edit"

        static let execute_prepared_intent_replays_file_mutation_write = "execute-prepared-intent-replays-file-mutation-write"
        static let execute_prepared_intent_replays_file_mutation_edit = "execute-prepared-intent-replays-file-mutation-edit"
        static let execute_prepared_intent_requires_approved = "execute-prepared-intent-requires-approved"
        static let execute_prepared_intent_rejects_missing_execution_tool = "execute-prepared-intent-rejects-missing-execution-tool"
        static let prepared_intent_operator_tool_set_registers_execute_when_execution_registry_provided = "prepared-intent-operator-tool-set-registers-execute-when-execution-registry-provided"

        static let list_file_mutations_tool = "list-file-mutations-tool"
        static let inspect_file_mutation_tool = "inspect-file-mutation-tool"
        static let inspect_file_mutation_loads_diff_artifact = "inspect-file-mutation-loads-diff-artifact"
        static let inspect_file_mutation_rejects_missing_id = "inspect-file-mutation-rejects-missing-id"

        static let file_mutation_rollback_preflight = "file-mutation-rollback-preflight"
        static let file_mutation_rollback_preflight_rejects_missing_id = "file-mutation-rollback-preflight-rejects-missing-id"
        static let prepared_file_mutation_rollback = "prepared-file-mutation-rollback"

        static let execute_prepared_intent_replays_file_mutation_rollback = "execute-prepared-intent-replays-file-mutation-rollback"
        static let execute_prepared_intent_rollback_records_mutation = "execute-prepared-intent-rollback-records-mutation"

        static let execute_prepared_intent_rejects_stale_file_mutation_write = "execute-prepared-intent-rejects-stale-file-mutation-write"
        static let execute_prepared_intent_rejects_stale_file_mutation_edit = "execute-prepared-intent-rejects-stale-file-mutation-edit"

        static let tool_use_batch_observe = "tool-use-batch-observe"
        static let tool_use_batch_approval_skip = "tool-use-batch-approval-skip"
        static let tool_use_batch_denial_skip = "tool-use-batch-denial-skip"

        static let model_route_planner_prefers_default = "model-route-planner-prefers-default"
        static let model_route_researcher_prefers_default = "model-route-researcher-prefers-default"
        static let model_route_researcher_selects_nova_pro_candidate = "model-route-researcher-selects-nova-pro-candidate"
        static let model_route_purpose_codable_roundtrip = "model-route-purpose-codable-roundtrip"

        static let model_id_known_models_codable_roundtrip = "model-id-known-models-codable-roundtrip"
        static let model_route_preferred_model_id = "model-route-preferred-model-id"

        static let mode_catalog_registers_default_modes = "mode-catalog-registers-default-modes"
        static let mode_planning_selects_planner_purpose = "mode-planning-selects-planner-purpose"
        static let mode_research_selects_researcher_purpose = "mode-research-selects-researcher-purpose"
        static let mode_coder_exposes_file_mutation_tools = "mode-coder-exposes-file-mutation-tools"
        static let mode_review_hides_mutation_tools = "mode-review-hides-mutation-tools"
        static let mode_private_requires_local_private_policy = "mode-private-requires-local-private-policy"
        static let mode_selection_codable_roundtrip = "mode-selection-codable-roundtrip"

        static let mode_application_filters_coder_tools = "mode-application-filters-coder-tools"
        static let mode_application_rejects_missing_tool = "mode-application-rejects-missing-tool"
        static let mode_application_reports_missing_skills = "mode-application-reports-missing-skills"
        static let mode_application_loads_available_skills = "mode-application-loads-available-skills"
    }
}
