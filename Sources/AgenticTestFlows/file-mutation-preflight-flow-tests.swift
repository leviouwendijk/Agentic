import Agentic
import Foundation
import Primitives
import TestFlows

extension AgenticFlowTesting {
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
            preflight.operationKind,
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
                ("operation", preflight.operationKind.rawValue),
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
            preflight.operationKind,
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
                ("operation", preflight.operationKind.rawValue),
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

        let intent = try await AgentFileMutationPreparedIntentBuilder(
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

        let intent = try await AgentFileMutationPreparedIntentBuilder(
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

private func mutationPreflightDiagnostics(
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
