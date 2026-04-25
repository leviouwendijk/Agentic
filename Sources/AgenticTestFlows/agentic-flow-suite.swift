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

        static let file_mutation_preflight_write = "file-mutation-preflight-write"
        static let file_mutation_preflight_edit = "file-mutation-preflight-edit"
        static let file_mutation_preflight_no_side_effects = "file-mutation-preflight-no-side-effects"
        static let prepared_file_mutation_write = "prepared-file-mutation-write"
        static let prepared_file_mutation_edit = "prepared-file-mutation-edit"
    }
}
