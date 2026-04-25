import Agentic
import Foundation
import Primitives
import TestFlows
import Writers

extension AgenticFlowTesting {
    static func runFileMutationStore() async throws -> [TestFlowDiagnostic] {
        let env = try MutationFlowWorkspace.make(
            AgenticFlowSuite.ID.file_mutation_store
        )
        defer {
            env.remove()
        }

        let editor = FileEditor(
            workspace: env.workspace
        )

        let target = try env.write(
            "old\n",
            to: "store.txt"
        )

        let result = try await editor.writeRecorded(
            "new\n",
            to: "store.txt",
            recorder: env.recorder,
            options: .init(
                mutation: .init(
                    toolCallID: "tool-call-1",
                    preparedIntentID: .init("intent-1"),
                    metadata: [
                        "flow": AgenticFlowSuite.ID.file_mutation_store
                    ]
                )
            )
        )

        let loaded = try Expect.notNil(
            try await env.store.load(
                id: result.mutationID
            ),
            "stored mutation record loads by id"
        )

        try Expect.equal(
            loaded.writerRecordID,
            result.writerRecordID,
            "stored Agentic record points at the Writers record"
        )

        _ = try Expect.notNil(
            try await env.store.loadWriterRecord(
                for: loaded
            ),
            "stored Writers record loads from Agentic wrapper"
        )

        try Expect.equal(
            try await env.store.list(.all).count,
            1,
            "mutation store lists one record"
        )

        try Expect.equal(
            try await env.store.list(
                .init(
                    target: target
                )
            ).count,
            1,
            "mutation store filters by target"
        )

        try Expect.equal(
            try await env.store.list(
                .init(
                    toolCallID: "tool-call-1"
                )
            ).count,
            1,
            "mutation store filters by tool call id"
        )

        try Expect.equal(
            try await env.store.list(
                .init(
                    preparedIntentID: .init("intent-1")
                )
            ).count,
            1,
            "mutation store filters by prepared intent id"
        )

        try await env.store.delete(
            id: result.mutationID
        )

        try Expect.isNil(
            try await env.store.load(
                id: result.mutationID
            ),
            "mutation store deletes Agentic record"
        )

        return mutationDiagnostics(
            [
                ("records", "saved/listed/queried/deleted"),
                ("writerRecordID", result.writerRecordID.uuidString)
            ]
        )
    }

    static func runFileEditorRecordedWrite() async throws -> [TestFlowDiagnostic] {
        let env = try MutationFlowWorkspace.make(
            AgenticFlowSuite.ID.file_editor_recorded_write
        )
        defer {
            env.remove()
        }

        try env.write(
            "old\n",
            to: "write.txt"
        )

        let editor = FileEditor(
            workspace: env.workspace
        )

        let result = try await editor.writeRecorded(
            "new\n",
            to: "write.txt",
            recorder: env.recorder,
            options: .init(
                mutation: .init(
                    metadata: [
                        "flow": AgenticFlowSuite.ID.file_editor_recorded_write
                    ]
                )
            )
        )

        try Expect.equal(
            try env.read("write.txt"),
            "new\n",
            "recorded write mutates the target file"
        )

        try Expect.true(
            result.mutation.hasChanges,
            "recorded write marks mutation as changed"
        )

        try Expect.true(
            result.mutation.rollbackable,
            "recorded write is rollbackable"
        )

        try Expect.equal(
            try await env.store.list(.all).count,
            1,
            "recorded write stores one mutation"
        )

        let before = try Expect.notNil(
            result.writerRecord.before?.content,
            "recorded write includes before snapshot content"
        )

        let after = try Expect.notNil(
            result.writerRecord.after?.content,
            "recorded write includes after snapshot content"
        )

        try Expect.equal(
            before,
            "old\n",
            "before snapshot matches original content"
        )

        try Expect.equal(
            after,
            "new\n",
            "after snapshot matches replacement content"
        )

        return mutationDiagnostics(
            [
                ("target", "write.txt"),
                ("writerRecordID", result.writerRecordID.uuidString)
            ]
        )
    }

    static func runFileEditorRecordedEdit() async throws -> [TestFlowDiagnostic] {
        let env = try MutationFlowWorkspace.make(
            AgenticFlowSuite.ID.file_editor_recorded_edit
        )
        defer {
            env.remove()
        }

        try env.write(
            "alpha\nbeta\ngamma\n",
            to: "edit.txt"
        )

        let editor = FileEditor(
            workspace: env.workspace
        )

        let result = try await editor.editRecorded(
            [
                .replaceFirst(
                    of: "beta",
                    with: "BETA"
                )
            ],
            at: "edit.txt",
            recorder: env.recorder,
            options: .init(
                mutation: .init(
                    metadata: [
                        "flow": AgenticFlowSuite.ID.file_editor_recorded_edit
                    ]
                )
            )
        )

        try Expect.equal(
            try env.read("edit.txt"),
            "alpha\nBETA\ngamma\n",
            "recorded edit mutates the target file"
        )

        try Expect.true(
            result.mutation.hasChanges,
            "recorded edit marks mutation as changed"
        )

        try Expect.true(
            result.mutation.rollbackable,
            "recorded edit is rollbackable"
        )

        try Expect.equal(
            result.mutation.operationKind.rawValue,
            "edit_operations",
            "recorded edit stores edit operation kind"
        )

        try Expect.equal(
            try await env.store.list(.all).count,
            1,
            "recorded edit stores one mutation"
        )

        return mutationDiagnostics(
            [
                ("target", "edit.txt"),
                ("writerRecordID", result.writerRecordID.uuidString)
            ]
        )
    }

    static func runFileToolRecordedWrite() async throws -> [TestFlowDiagnostic] {
        let env = try MutationFlowWorkspace.make(
            AgenticFlowSuite.ID.file_tool_recorded_write
        )
        defer {
            env.remove()
        }

        try env.write(
            "before\n",
            to: "tool-write.txt"
        )

        let tool = WriteFileTool(
            recorder: env.recorder
        )

        let value = try await tool.call(
            input: try JSONToolBridge.encode(
                WriteFileToolInput(
                    path: "tool-write.txt",
                    content: "after\n"
                )
            ),
            workspace: env.workspace
        )

        let output = try JSONToolBridge.decode(
            WriteFileToolOutput.self,
            from: value
        )

        let mutation = try Expect.notNil(
            output.mutation,
            "write_file output includes mutation summary"
        )

        try Expect.equal(
            try env.read("tool-write.txt"),
            "after\n",
            "write_file with recorder mutates file"
        )

        try Expect.equal(
            mutation.backupPolicy,
            .session_store,
            "write_file uses normal session backup policy"
        )

        try Expect.equal(
            mutation.payloadPolicy,
            .external_content,
            "write_file uses external Writers payload storage"
        )

        try Expect.equal(
            try await env.store.list(.all).count,
            1,
            "write_file with recorder stores one mutation"
        )

        return mutationDiagnostics(
            [
                ("target", output.path),
                ("writerRecordID", mutation.writerRecordID.uuidString)
            ]
        )
    }

    static func runFileToolRecordedEdit() async throws -> [TestFlowDiagnostic] {
        let env = try MutationFlowWorkspace.make(
            AgenticFlowSuite.ID.file_tool_recorded_edit
        )
        defer {
            env.remove()
        }

        try env.write(
            "alpha\nbeta\ngamma\n",
            to: "tool-edit.txt"
        )

        let tool = EditFileTool(
            recorder: env.recorder
        )

        let value = try await tool.call(
            input: try JSONToolBridge.encode(
                EditFileToolInput(
                    path: "tool-edit.txt",
                    operations: [
                        .init(
                            kind: .replaceFirst,
                            target: "beta",
                            replacement: "BETA"
                        )
                    ]
                )
            ),
            workspace: env.workspace
        )

        let output = try JSONToolBridge.decode(
            EditFileToolOutput.self,
            from: value
        )

        let mutation = try Expect.notNil(
            output.mutation,
            "edit_file output includes mutation summary"
        )

        try Expect.equal(
            try env.read("tool-edit.txt"),
            "alpha\nBETA\ngamma\n",
            "edit_file with recorder mutates file"
        )

        try Expect.equal(
            output.operationCount,
            1,
            "edit_file output reports one operation"
        )

        try Expect.equal(
            try await env.store.list(.all).count,
            1,
            "edit_file with recorder stores one mutation"
        )

        return mutationDiagnostics(
            [
                ("target", output.path),
                ("writerRecordID", mutation.writerRecordID.uuidString)
            ]
        )
    }

    static func runNoLocalBackupDefault() async throws -> [TestFlowDiagnostic] {
        let env = try MutationFlowWorkspace.make(
            AgenticFlowSuite.ID.no_local_backup_default
        )
        defer {
            env.remove()
        }

        try env.write(
            "before\n",
            to: "backup.txt"
        )

        let editor = FileEditor(
            workspace: env.workspace
        )

        _ = try await editor.writeRecorded(
            "after\n",
            to: "backup.txt",
            recorder: env.recorder,
            options: .init(
                mutation: .init(
                    metadata: [
                        "flow": AgenticFlowSuite.ID.no_local_backup_default
                    ]
                )
            )
        )

        let backupdir = env.mutationdir.appendingPathComponent(
            "backups",
            isDirectory: true
        )

        try Expect.notEmpty(
            childURLs(
                backupdir
            ),
            "default recorded write stores backups in Agentic session storage"
        )

        try Expect.false(
            containsPathComponent(
                "safe-file-backups",
                under: env.projectdir
            ),
            "default recorded write does not create project-local safe-file-backups"
        )

        return mutationDiagnostics(
            [
                ("sessionBackups", backupdir.path),
                ("localBackups", "absent")
            ]
        )
    }

    static func runFileMutationDiffArtifact() async throws -> [TestFlowDiagnostic] {
        let env = try MutationFlowWorkspace.make(
            AgenticFlowSuite.ID.file_mutation_diff_artifact
        )
        defer {
            env.remove()
        }

        try env.write(
            "one\ntwo\n",
            to: "diff.txt"
        )

        let editor = FileEditor(
            workspace: env.workspace
        )

        let result = try await editor.writeRecorded(
            "one\ntwo changed\n",
            to: "diff.txt",
            recorder: env.recorder,
            options: .init(
                mutation: .init(
                    metadata: [
                        "flow": AgenticFlowSuite.ID.file_mutation_diff_artifact
                    ]
                )
            )
        )

        let artifact = try Expect.notNil(
            result.artifacts.first,
            "changed recorded mutation emits a diff artifact"
        )

        try Expect.equal(
            artifact.kind,
            .diff,
            "recorded mutation artifact is a diff"
        )

        let loaded = try Expect.notNil(
            try await env.artifactStore.load(
                id: artifact.id
            ),
            "diff artifact can be loaded"
        )

        try Expect.contains(
            loaded.content,
            "two changed",
            "diff artifact contains replacement text"
        )

        let noop = try await editor.writeRecorded(
            "one\ntwo changed\n",
            to: "diff.txt",
            recorder: env.recorder,
            options: .init(
                mutation: .init(
                    metadata: [
                        "flow": "no-op-diff-artifact-check"
                    ]
                )
            )
        )

        try Expect.isEmpty(
            noop.artifacts,
            "no-op recorded mutation does not emit diff artifact"
        )

        return mutationDiagnostics(
            [
                ("artifactID", artifact.id),
                ("artifactKind", artifact.kind.rawValue)
            ]
        )
    }
}

private struct MutationFlowWorkspace {
    let rootdir: URL
    let projectdir: URL
    let sessiondir: URL
    let mutationdir: URL
    let artifactdir: URL
    let sessionID: String
    let workspace: AgentWorkspace
    let store: FileAgentFileMutationStore
    let artifactStore: FileAgentArtifactStore
    let recorder: AgentFileMutationRecorder

    static func make(
        _ name: String
    ) throws -> Self {
        let rootdir = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "agentic-\(safeName(name))-\(UUID().uuidString)",
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

        return .init(
            rootdir: rootdir,
            projectdir: projectdir,
            sessiondir: sessiondir,
            mutationdir: mutationdir,
            artifactdir: artifactdir,
            sessionID: sessionID,
            workspace: workspace,
            store: store,
            artifactStore: artifactStore,
            recorder: recorder
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

private func mutationDiagnostics(
    _ pairs: [(String, String)]
) -> [TestFlowDiagnostic] {
    pairs.map { key, value in
        .field(
            key,
            value
        )
    }
}

private func safeName(
    _ name: String
) -> String {
    name.map { character in
        character.isLetter || character.isNumber
            ? String(character)
            : "-"
    }
    .joined()
}

private func childURLs(
    _ url: URL
) -> [URL] {
    (
        try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [
                .skipsHiddenFiles
            ]
        )
    ) ?? []
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
