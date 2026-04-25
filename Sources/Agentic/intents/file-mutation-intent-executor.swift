import Foundation
import Primitives

public enum FileMutationIntentExecutionError: Error, Sendable, LocalizedError {
    case unsupportedActionType(String)
    case missingExactInputs(PreparedIntentIdentifier)

    public var errorDescription: String? {
        switch self {
        case .unsupportedActionType(let actionType):
            return "Unsupported file mutation prepared intent action type '\(actionType)'."

        case .missingExactInputs(let id):
            return "Prepared file mutation intent '\(id.rawValue)' is missing exact replay inputs."
        }
    }
}

public struct FileMutationIntentExecutor: Sendable {
    public static let name = "file_mutation_intent_executor"

    public let manager: PreparedIntentManager
    public let workspace: AgentWorkspace
    public let recorder: AgentFileMutationRecorder

    public init(
        manager: PreparedIntentManager,
        workspace: AgentWorkspace,
        recorder: AgentFileMutationRecorder
    ) {
        self.manager = manager
        self.workspace = workspace
        self.recorder = recorder
    }

    public func execute(
        _ id: PreparedIntentIdentifier
    ) async throws -> PreparedIntent {
        let intent = try await manager.executableIntent(
            id: id
        )
        let startedAt = Date()

        guard let action = FileMutationIntentAction(
            actionType: intent.actionType
        ) else {
            try await fail(
                intent: intent,
                startedAt: startedAt,
                summary: "Prepared file mutation intent has an unsupported action type.",
                error: FileMutationIntentExecutionError.unsupportedActionType(
                    intent.actionType
                ),
                executionToolName: nil,
                metadata: [
                    "executor": Self.name,
                    "actionType": intent.actionType
                ]
            )
        }

        guard let exactInputs = intent.reviewPayload.exactInputs else {
            try await fail(
                intent: intent,
                startedAt: startedAt,
                summary: "Prepared file mutation intent is missing exact replay inputs.",
                error: FileMutationIntentExecutionError.missingExactInputs(
                    intent.id
                ),
                executionToolName: action.toolName,
                metadata: metadata(
                    intent: intent,
                    action: action
                )
            )
        }

        do {
            let result = try await execute(
                action,
                intentID: intent.id,
                exactInputs: exactInputs
            )

            return try await manager.recordExecution(
                id: intent.id,
                record: .init(
                    intentID: intent.id,
                    executionToolName: action.toolName,
                    status: .succeeded,
                    summary: "Executed prepared file mutation \(action.rawValue).",
                    startedAt: startedAt,
                    completedAt: Date(),
                    result: result,
                    metadata: metadata(
                        intent: intent,
                        action: action
                    )
                )
            )
        } catch {
            try await fail(
                intent: intent,
                startedAt: startedAt,
                summary: "Prepared file mutation execution failed.",
                error: error,
                executionToolName: action.toolName,
                metadata: metadata(
                    intent: intent,
                    action: action
                )
            )
        }
    }
}

private extension FileMutationIntentExecutor {
    func execute(
        _ action: FileMutationIntentAction,
        intentID: PreparedIntentIdentifier,
        exactInputs: JSONValue
    ) async throws -> JSONValue {
        switch action {
        case .write:
            let decoded = try JSONToolBridge.decode(
                WriteFileToolInput.self,
                from: exactInputs
            )

            return try await WriteFileTool(
                recorder: recorder,
                context: mutationContext(
                    intentID: intentID,
                    action: action
                )
            ).call(
                input: try JSONToolBridge.encode(
                    decoded
                ),
                workspace: workspace
            )

        case .edit:
            let decoded = try JSONToolBridge.decode(
                EditFileToolInput.self,
                from: exactInputs
            )

            return try await EditFileTool(
                recorder: recorder,
                context: mutationContext(
                    intentID: intentID,
                    action: action
                )
            ).call(
                input: try JSONToolBridge.encode(
                    decoded
                ),
                workspace: workspace
            )
        }
    }

    func mutationContext(
        intentID: PreparedIntentIdentifier,
        action: FileMutationIntentAction
    ) -> AgentFileMutationContext {
        .init(
            preparedIntentID: intentID,
            metadata: [
                "executor": Self.name,
                "prepared_intent_id": intentID.rawValue,
                "intent_action": action.rawValue,
                "intent_action_type": action.actionType
            ]
        )
    }

    func metadata(
        intent: PreparedIntent,
        action: FileMutationIntentAction
    ) -> [String: String] {
        [
            "executor": Self.name,
            "prepared_intent_id": intent.id.rawValue,
            "action": action.rawValue,
            "actionType": intent.actionType,
            "toolName": action.toolName
        ]
    }

    func fail(
        intent: PreparedIntent,
        startedAt: Date,
        summary: String,
        error: Error,
        executionToolName: String?,
        metadata: [String: String]
    ) async throws -> Never {
        _ = try await manager.recordExecution(
            id: intent.id,
            record: .init(
                intentID: intent.id,
                executionToolName: executionToolName,
                status: .failed,
                summary: summary,
                startedAt: startedAt,
                completedAt: Date(),
                result: nil,
                errorMessage: String(
                    describing: error
                ),
                metadata: metadata
            )
        )

        throw error
    }
}
