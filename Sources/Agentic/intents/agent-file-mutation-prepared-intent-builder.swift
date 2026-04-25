import Foundation
import Primitives

public struct AgentFileMutationPreparedIntentBuilder: Sendable {
    public var sessionID: String?
    public var expiresAt: Date?

    public init(
        sessionID: String? = nil,
        expiresAt: Date? = nil
    ) {
        self.sessionID = sessionID
        self.expiresAt = expiresAt
    }

    public func draft(
        for preflight: AgentFileMutationPreflight
    ) throws -> PreparedIntentDraft {
        let payload = PreparedIntentReviewPayload(
            title: "\(preflight.operationKind.titleVerb): \(preflight.targetPath)",
            summary: summary(
                for: preflight
            ),
            actionType: preflight.operationKind.actionType,
            risk: preflight.risk,
            target: preflight.targetPath,
            exactInputs: preflight.exactReplayInput,
            expectedSideEffects: preflight.sideEffects,
            policyChecks: preflight.policyChecks,
            warnings: preflight.warnings,
            expiresAt: expiresAt,
            metadata: reviewMetadata(
                for: preflight
            )
        )

        return PreparedIntentDraft(
            sessionID: sessionID,
            actionType: preflight.operationKind.actionType,
            reviewPayload: payload,
            executionToolName: nil,
            idempotencyKey: nil,
            metadata: draftMetadata(
                for: preflight
            )
        )
    }

    public func create(
        _ preflight: AgentFileMutationPreflight,
        using manager: PreparedIntentManager
    ) async throws -> PreparedIntent {
        try await manager.create(
            draft(
                for: preflight
            )
        )
    }
}

private extension AgentFileMutationPreparedIntentBuilder {
    func summary(
        for preflight: AgentFileMutationPreflight
    ) -> String {
        var lines: [String] = [
            "Stage a \(preflight.operationKind.rawValue) mutation for '\(preflight.targetPath)'.",
            "",
            "This prepared intent is review-only. It does not execute the file mutation."
        ]

        lines.append(
            "Root: \(preflight.rootID.rawValue)"
        )
        lines.append(
            "Backup policy: \(preflight.backupPolicy.rawValue)"
        )
        lines.append(
            "Payload policy: \(preflight.payloadPolicy.rawValue)"
        )

        if let diffPreview = preflight.diffPreview {
            lines.append(
                "Diff preview: \(diffPreview.insertedLineCount) insertion(s), \(diffPreview.deletedLineCount) deletion(s)."
            )
        } else {
            lines.append(
                "Diff preview: unavailable."
            )
        }

        if preflight.willRecordSessionMutation {
            lines.append(
                "Execution is expected to record an AgentFileMutationRecord."
            )
        } else {
            lines.append(
                "Execution is not expected to record an Agentic mutation record unless an executor attaches a recorder."
            )
        }

        if preflight.willStoreBackupPayload {
            lines.append(
                "Execution is expected to store backup payloads in session mutation storage."
            )
        }

        if preflight.willEmitDiffArtifact {
            lines.append(
                "Execution may emit a diff artifact."
            )
        }

        return lines.joined(
            separator: "\n"
        )
    }

    func reviewMetadata(
        for preflight: AgentFileMutationPreflight
    ) -> [String: String] {
        [
            "operationKind": preflight.operationKind.rawValue,
            "toolName": preflight.operationKind.toolName,
            "rootID": preflight.rootID.rawValue,
            "path": preflight.path,
            "targetPath": preflight.targetPath,
            "backupPolicy": preflight.backupPolicy.rawValue,
            "payloadPolicy": preflight.payloadPolicy.rawValue,
            "willRecordSessionMutation": String(preflight.willRecordSessionMutation),
            "willStoreBackupPayload": String(preflight.willStoreBackupPayload),
            "willEmitDiffArtifact": String(preflight.willEmitDiffArtifact)
        ]
    }

    func draftMetadata(
        for preflight: AgentFileMutationPreflight
    ) -> [String: String] {
        [
            "kind": "file_mutation",
            "operationKind": preflight.operationKind.rawValue,
            "rootID": preflight.rootID.rawValue,
            "path": preflight.path,
            "targetPath": preflight.targetPath
        ]
    }
}
