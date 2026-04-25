import Agentic
import Foundation
import Primitives
import TestFlows

extension AgenticFlowTesting {
    static func runExecutePreparedFileMutationWrite() async throws -> [TestFlowDiagnostic] {
        let env = try MutationPreflightFlowWorkspace.make(
            AgenticFlowSuite.ID.execute_prepared_file_mutation_write
        )
        defer {
            env.remove()
        }

        try env.write(
            "old\n",
            to: "execute-write.txt"
        )

        let preflight = try await AgentFileMutationPreflight.write(
            .init(
                path: "execute-write.txt",
                content: "new\n"
            ),
            workspace: env.workspace,
            recorder: env.recorder
        )

        let intent = try await FileMutationIntentBuilder(
            sessionID: env.sessionID
        ).create(
            preflight,
            using: env.intentManager
        )

        _ = try await env.intentManager.review(
            id: intent.id,
            decision: .approve
        )

        let executed = try await FileMutationIntentExecutor(
            manager: env.intentManager,
            workspace: env.workspace,
            recorder: env.recorder
        ).execute(
            intent.id
        )

        try Expect.equal(
            executed.status,
            .executed,
            "prepared write intent executed"
        )

        _ = try Expect.notNil(
            executed.executionRecord,
            "prepared write intent has execution record"
        )

        _ = try Expect.notNil(
            executed.executionRecord?.result,
            "prepared write intent has execution result"
        )

        try Expect.equal(
            try env.read("execute-write.txt"),
            "new\n",
            "prepared write execution mutates target file"
        )

        let mutations = try await env.store.list(
            .all
        )

        try Expect.equal(
            mutations.count,
            1,
            "prepared write execution records one mutation"
        )

        let mutation = try Expect.notNil(
            mutations.first,
            "prepared write execution mutation record"
        )

        try Expect.equal(
            mutation.preparedIntentID,
            intent.id,
            "prepared write mutation links prepared intent id"
        )

        return mutationPreflightDiagnostics(
            [
                ("intent", executed.id.rawValue),
                ("status", executed.status.rawValue),
                ("file", "mutated"),
                ("mutations", "\(mutations.count)")
            ]
        )
    }

    static func runExecutePreparedFileMutationEdit() async throws -> [TestFlowDiagnostic] {
        let env = try MutationPreflightFlowWorkspace.make(
            AgenticFlowSuite.ID.execute_prepared_file_mutation_edit
        )
        defer {
            env.remove()
        }

        try env.write(
            "alpha\nbeta\n",
            to: "execute-edit.txt"
        )

        let preflight = try await AgentFileMutationPreflight.edit(
            .init(
                path: "execute-edit.txt",
                operations: [
                    .init(
                        kind: .replaceFirst,
                        target: "beta",
                        replacement: "gamma"
                    )
                ]
            ),
            workspace: env.workspace,
            recorder: env.recorder
        )

        let intent = try await FileMutationIntentBuilder(
            sessionID: env.sessionID
        ).create(
            preflight,
            using: env.intentManager
        )

        _ = try await env.intentManager.review(
            id: intent.id,
            decision: .approve
        )

        let executed = try await FileMutationIntentExecutor(
            manager: env.intentManager,
            workspace: env.workspace,
            recorder: env.recorder
        ).execute(
            intent.id
        )

        try Expect.equal(
            executed.status,
            .executed,
            "prepared edit intent executed"
        )

        _ = try Expect.notNil(
            executed.executionRecord,
            "prepared edit intent has execution record"
        )

        _ = try Expect.notNil(
            executed.executionRecord?.result,
            "prepared edit intent has execution result"
        )

        try Expect.equal(
            try env.read("execute-edit.txt"),
            "alpha\ngamma\n",
            "prepared edit execution mutates target file"
        )

        let mutations = try await env.store.list(
            .all
        )

        try Expect.equal(
            mutations.count,
            1,
            "prepared edit execution records one mutation"
        )

        let mutation = try Expect.notNil(
            mutations.first,
            "prepared edit execution mutation record"
        )

        try Expect.equal(
            mutation.preparedIntentID,
            intent.id,
            "prepared edit mutation links prepared intent id"
        )

        return mutationPreflightDiagnostics(
            [
                ("intent", executed.id.rawValue),
                ("status", executed.status.rawValue),
                ("file", "mutated"),
                ("mutations", "\(mutations.count)")
            ]
        )
    }

    static func runExecutePreparedFileMutationRequiresApproved() async throws -> [TestFlowDiagnostic] {
        let env = try MutationPreflightFlowWorkspace.make(
            AgenticFlowSuite.ID.execute_prepared_file_mutation_requires_approved
        )
        defer {
            env.remove()
        }

        try env.write(
            "old\n",
            to: "requires-approved.txt"
        )

        let preflight = try await AgentFileMutationPreflight.write(
            .init(
                path: "requires-approved.txt",
                content: "new\n"
            ),
            workspace: env.workspace,
            recorder: env.recorder
        )

        let intent = try await FileMutationIntentBuilder(
            sessionID: env.sessionID
        ).create(
            preflight,
            using: env.intentManager
        )

        do {
            _ = try await FileMutationIntentExecutor(
                manager: env.intentManager,
                workspace: env.workspace,
                recorder: env.recorder
            ).execute(
                intent.id
            )

            throw FlowTestError.unexpectedResult(
                "pending prepared file mutation intent unexpectedly executed"
            )
        } catch PreparedIntentError.notApproved(let id, let status) {
            try Expect.equal(
                id,
                intent.id,
                "notApproved id"
            )

            try Expect.equal(
                status,
                .pending_review,
                "notApproved status"
            )

            try Expect.equal(
                try env.read("requires-approved.txt"),
                "old\n",
                "unapproved prepared intent does not mutate target file"
            )

            let persisted = try await env.intentManager.get(
                intent.id
            )

            try Expect.equal(
                persisted.status,
                .pending_review,
                "unapproved prepared intent remains pending"
            )

            return mutationPreflightDiagnostics(
                [
                    ("intent", intent.id.rawValue),
                    ("status", persisted.status.rawValue),
                    ("error", "notApproved")
                ]
            )
        }
    }

    static func runExecutePreparedFileMutationRejectsUnknownAction() async throws -> [TestFlowDiagnostic] {
        let env = try MutationPreflightFlowWorkspace.make(
            AgenticFlowSuite.ID.execute_prepared_file_mutation_rejects_unknown_action
        )
        defer {
            env.remove()
        }

        try env.write(
            "old\n",
            to: "unknown-action.txt"
        )

        let exactInputs = try JSONToolBridge.encode(
            WriteFileToolInput(
                path: "unknown-action.txt",
                content: "new\n"
            )
        )

        let intent = try await env.intentManager.create(
            .init(
                sessionID: env.sessionID,
                actionType: "file_mutation.unknown",
                reviewPayload: .init(
                    title: "Unknown file mutation action",
                    summary: "Prepared intent with unsupported file mutation action.",
                    actionType: "file_mutation.unknown",
                    risk: .boundedmutate,
                    target: "unknown-action.txt",
                    exactInputs: exactInputs,
                    expectedSideEffects: [
                        "unsupported test action"
                    ],
                    policyChecks: [
                        "test_fixture"
                    ]
                )
            )
        )

        _ = try await env.intentManager.review(
            id: intent.id,
            decision: .approve
        )

        do {
            _ = try await FileMutationIntentExecutor(
                manager: env.intentManager,
                workspace: env.workspace,
                recorder: env.recorder
            ).execute(
                intent.id
            )

            throw FlowTestError.unexpectedResult(
                "unknown prepared file mutation action unexpectedly executed"
            )
        } catch FileMutationIntentExecutionError.unsupportedActionType(let actionType) {
            try Expect.equal(
                actionType,
                "file_mutation.unknown",
                "unknown action type"
            )

            try Expect.equal(
                try env.read("unknown-action.txt"),
                "old\n",
                "unknown prepared intent action does not mutate target file"
            )

            let failed = try await env.intentManager.get(
                intent.id
            )

            try Expect.equal(
                failed.status,
                .execution_failed,
                "unknown prepared intent action marks execution failed"
            )

            _ = try Expect.notNil(
                failed.executionRecord,
                "unknown prepared intent action has failure execution record"
            )

            return mutationPreflightDiagnostics(
                [
                    ("intent", intent.id.rawValue),
                    ("status", failed.status.rawValue),
                    ("error", actionType)
                ]
            )
        }
    }
    static func runFileMutationPreflightWrite() async throws -> [TestFlowDiagnostic] {
        let env = try MutationPreflightFlowWorkspace.make(
            AgenticFlowSuite.ID.file_mutation_preflight_write
        )
        defer {
            env.remove()
        }

        try env.write(
            "old\n",
            to: "write.txt"
        )

        let preflight = try await AgentFileMutationPreflight.write(
            .init(
                path: "write.txt",
                content: "new\n"
            ),
            workspace: env.workspace,
            recorder: env.recorder
        )

        try Expect.equal(
            preflight.action,
            .write,
            "write preflight operation kind"
        )

        _ = try Expect.notNil(
            preflight.diffPreview,
            "write preflight has diff preview"
        )

        try Expect.equal(
            preflight.willRecordSessionMutation,
            true,
            "write preflight describes session mutation recording"
        )

        try Expect.equal(
            preflight.willStoreBackupPayload,
            true,
            "write preflight describes session backup payload storage"
        )

        try Expect.equal(
            try env.read("write.txt"),
            "old\n",
            "write preflight does not mutate target file"
        )

        return mutationPreflightDiagnostics(
            [
                ("action", preflight.action.rawValue),
                ("target", preflight.targetPath),
                ("preview", "ok")
            ]
        )
    }

    static func runFileMutationPreflightEdit() async throws -> [TestFlowDiagnostic] {
        let env = try MutationPreflightFlowWorkspace.make(
            AgenticFlowSuite.ID.file_mutation_preflight_edit
        )
        defer {
            env.remove()
        }

        try env.write(
            "alpha\nbeta\n",
            to: "edit.txt"
        )

        let preflight = try await AgentFileMutationPreflight.edit(
            .init(
                path: "edit.txt",
                operations: [
                    .init(
                        kind: .replaceFirst,
                        target: "beta",
                        replacement: "gamma"
                    )
                ]
            ),
            workspace: env.workspace,
            recorder: env.recorder
        )

        try Expect.equal(
            preflight.action,
            .edit,
            "edit preflight operation kind"
        )

        _ = try Expect.notNil(
            preflight.diffPreview,
            "edit preflight has diff preview"
        )

        try Expect.equal(
            preflight.willRecordSessionMutation,
            true,
            "edit preflight describes session mutation recording"
        )

        try Expect.equal(
            try env.read("edit.txt"),
            "alpha\nbeta\n",
            "edit preflight does not mutate target file"
        )

        return mutationPreflightDiagnostics(
            [
                ("action", preflight.action.rawValue),
                ("target", preflight.targetPath),
                ("preview", "ok")
            ]
        )
    }

    static func runFileMutationPreflightNoSideEffects() async throws -> [TestFlowDiagnostic] {
        let env = try MutationPreflightFlowWorkspace.make(
            AgenticFlowSuite.ID.file_mutation_preflight_no_side_effects
        )
        defer {
            env.remove()
        }

        try env.write(
            "before\n",
            to: "no-side-effects.txt"
        )

        _ = try await AgentFileMutationPreflight.write(
            .init(
                path: "no-side-effects.txt",
                content: "after\n"
            ),
            workspace: env.workspace,
            recorder: env.recorder
        )

        try Expect.equal(
            try env.read("no-side-effects.txt"),
            "before\n",
            "preflight does not mutate file contents"
        )

        try Expect.equal(
            try await env.store.list(.all).count,
            0,
            "preflight does not write mutation records"
        )

        try Expect.equal(
            try await env.artifactStore.list(
                kinds: [],
                latestFirst: true,
                limit: nil
            ).count,
            0,
            "preflight does not emit artifacts"
        )

        try Expect.equal(
            containsPathComponent(
                "content",
                under: env.mutationdir
            ),
            false,
            "preflight does not create backup payload content"
        )

        return mutationPreflightDiagnostics(
            [
                ("file", "unchanged"),
                ("mutations", "0"),
                ("artifacts", "0")
            ]
        )
    }

    static func runPreparedFileMutationWrite() async throws -> [TestFlowDiagnostic] {
        let env = try MutationPreflightFlowWorkspace.make(
            AgenticFlowSuite.ID.prepared_file_mutation_write
        )
        defer {
            env.remove()
        }

        try env.write(
            "old\n",
            to: "prepared-write.txt"
        )

        let preflight = try await AgentFileMutationPreflight.write(
            .init(
                path: "prepared-write.txt",
                content: "new\n"
            ),
            workspace: env.workspace,
            recorder: env.recorder
        )

        let intent = try await FileMutationIntentBuilder(
            sessionID: env.sessionID
        ).create(
            preflight,
            using: env.intentManager
        )

        try Expect.equal(
            intent.status,
            .pending_review,
            "prepared write intent starts pending review"
        )

        try Expect.isNil(
            intent.executionToolName,
            "prepared write intent does not declare an executor yet"
        )

        let exactInputs = try Expect.notNil(
            intent.reviewPayload.exactInputs,
            "prepared write intent has exact inputs"
        )

        let decoded = try JSONToolBridge.decode(
            WriteFileToolInput.self,
            from: exactInputs
        )

        try Expect.equal(
            decoded.path,
            "prepared-write.txt",
            "prepared write exactInputs are replayable"
        )

        try Expect.equal(
            decoded.content,
            "new\n",
            "prepared write exactInputs preserve content"
        )

        try Expect.equal(
            try env.read("prepared-write.txt"),
            "old\n",
            "prepared write intent creation does not mutate target file"
        )

        return mutationPreflightDiagnostics(
            [
                ("intent", intent.id.rawValue),
                ("status", intent.status.rawValue),
                ("exactInputs", "write")
            ]
        )
    }

    static func runPreparedFileMutationEdit() async throws -> [TestFlowDiagnostic] {
        let env = try MutationPreflightFlowWorkspace.make(
            AgenticFlowSuite.ID.prepared_file_mutation_edit
        )
        defer {
            env.remove()
        }

        try env.write(
            "alpha\nbeta\n",
            to: "prepared-edit.txt"
        )

        let preflight = try await AgentFileMutationPreflight.edit(
            .init(
                path: "prepared-edit.txt",
                operations: [
                    .init(
                        kind: .replaceFirst,
                        target: "beta",
                        replacement: "gamma"
                    )
                ]
            ),
            workspace: env.workspace,
            recorder: env.recorder
        )

        let intent = try await FileMutationIntentBuilder(
            sessionID: env.sessionID
        ).create(
            preflight,
            using: env.intentManager
        )

        try Expect.equal(
            intent.status,
            .pending_review,
            "prepared edit intent starts pending review"
        )

        try Expect.isNil(
            intent.executionToolName,
            "prepared edit intent does not declare an executor yet"
        )

        let exactInputs = try Expect.notNil(
            intent.reviewPayload.exactInputs,
            "prepared edit intent has exact inputs"
        )

        let decoded = try JSONToolBridge.decode(
            EditFileToolInput.self,
            from: exactInputs
        )

        try Expect.equal(
            decoded.path,
            "prepared-edit.txt",
            "prepared edit exactInputs are replayable"
        )

        try Expect.equal(
            decoded.operations.count,
            1,
            "prepared edit exactInputs preserve operation count"
        )

        try Expect.equal(
            try env.read("prepared-edit.txt"),
            "alpha\nbeta\n",
            "prepared edit intent creation does not mutate target file"
        )

        return mutationPreflightDiagnostics(
            [
                ("intent", intent.id.rawValue),
                ("status", intent.status.rawValue),
                ("exactInputs", "edit")
            ]
        )
    }
}

private struct MutationPreflightFlowWorkspace {
    let rootdir: URL
    let projectdir: URL
    let mutationdir: URL
    let artifactdir: URL
    let preparedIntentsdir: URL
    let sessionID: String
    let workspace: AgentWorkspace
    let store: FileAgentFileMutationStore
    let artifactStore: FileAgentArtifactStore
    let recorder: AgentFileMutationRecorder
    let intentManager: PreparedIntentManager

    static func make(
        _ name: String
    ) throws -> Self {
        let rootdir = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "agentic-\(mutationPreflightSafeName(name))-\(UUID().uuidString)",
                isDirectory: true
            )

        let projectdir = rootdir.appendingPathComponent(
            "project",
            isDirectory: true
        )
        let sessiondir = rootdir.appendingPathComponent(
            "session",
            isDirectory: true
        )
        let mutationdir = sessiondir.appendingPathComponent(
            "mutations",
            isDirectory: true
        )
        let artifactdir = sessiondir.appendingPathComponent(
            "artifacts",
            isDirectory: true
        )
        let preparedIntentsdir = sessiondir.appendingPathComponent(
            "prepared-intents",
            isDirectory: true
        )

        try FileManager.default.createDirectory(
            at: projectdir,
            withIntermediateDirectories: true
        )

        try FileManager.default.createDirectory(
            at: sessiondir,
            withIntermediateDirectories: true
        )

        let sessionID = "session-\(UUID().uuidString)"
        let workspace = try AgentWorkspace(
            root: projectdir
        )
        let store = FileAgentFileMutationStore(
            sessionID: sessionID,
            mutationdir: mutationdir
        )
        let artifactStore = FileAgentArtifactStore(
            sessionID: sessionID,
            artifactdir: artifactdir
        )
        let backupStore = AgentWriteBackupStore(
            mutationdir: mutationdir
        )
        let recorder = AgentFileMutationRecorder(
            sessionID: sessionID,
            store: store,
            artifacts: artifactStore,
            backups: backupStore,
            policy: .normal
        )
        let intentManager = PreparedIntentManager(
            store: FilePreparedIntentStore(
                preparedIntentsdir: preparedIntentsdir
            )
        )

        return .init(
            rootdir: rootdir,
            projectdir: projectdir,
            mutationdir: mutationdir,
            artifactdir: artifactdir,
            preparedIntentsdir: preparedIntentsdir,
            sessionID: sessionID,
            workspace: workspace,
            store: store,
            artifactStore: artifactStore,
            recorder: recorder,
            intentManager: intentManager
        )
    }

    func remove() {
        try? FileManager.default.removeItem(
            at: rootdir
        )
    }

    @discardableResult
    func write(
        _ text: String,
        to relativePath: String
    ) throws -> URL {
        let url = projectdir.appendingPathComponent(
            relativePath,
            isDirectory: false
        )

        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        try text.write(
            to: url,
            atomically: true,
            encoding: .utf8
        )

        return url.standardizedFileURL
    }

    func read(
        _ relativePath: String
    ) throws -> String {
        try String(
            contentsOf: projectdir.appendingPathComponent(
                relativePath,
                isDirectory: false
            ),
            encoding: .utf8
        )
    }
}

internal func mutationPreflightDiagnostics(
    _ pairs: [(String, String)]
) -> [TestFlowDiagnostic] {
    pairs.map { key, value in
        .field(
            key,
            value
        )
    }
}

private func mutationPreflightSafeName(
    _ name: String
) -> String {
    name.map { character in
        character.isLetter || character.isNumber
            ? String(character)
            : "-"
    }
    .joined()
}

private func containsPathComponent(
    _ component: String,
    under root: URL
) -> Bool {
    guard let enumerator = FileManager.default.enumerator(
        at: root,
        includingPropertiesForKeys: nil,
        options: [
            .skipsHiddenFiles
        ]
    ) else {
        return false
    }

    for case let url as URL in enumerator {
        if url.lastPathComponent == component {
            return true
        }
    }

    return false
}
