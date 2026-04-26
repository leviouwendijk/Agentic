import Position
import Primitives
import Writers
import Difference
import Readers
import Foundation

public struct EditFileTool: AgentTool {
    public static let identifier: AgentToolIdentifier = "edit_file"
    public static let description = "Apply one or more structured edit operations to a file in the workspace."
    public static let risk: ActionRisk = .boundedmutate

    public let recorder: AgentFileMutationRecorder?
    public let context: AgentFileMutationContext

    public init(
        recorder: AgentFileMutationRecorder? = nil,
        context: AgentFileMutationContext = .empty
    ) {
        self.recorder = recorder
        self.context = context
    }

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let workspace = try FileToolSupport.requireWorkspace(
            workspace,
            toolName: name
        )

        let decoded = try JSONToolBridge.decode(
            EditFileToolInput.self,
            from: input
        )

        let authorized = try FileToolAccess.authorize(
            workspace: workspace,
            rootID: decoded.rootID,
            path: decoded.path,
            capability: .write,
            toolName: name,
            type: .file
        )

        let operations = try decoded.operations.map { operation in
            try operation.standardOperation()
        }

        let editor = FileEditor(
            workspace: workspace
        )

        let preview = try editor.previewEdit(
            operations,
            at: authorized.scopedPath
        )

        let diffPreview = makeDiffPreview(
            authorized: authorized,
            preview: preview,
            operationCount: operations.count
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace.rootURL.path,
            targetPaths: [
                authorized.presentationPath
            ],
            summary: "Apply \(decoded.operations.count) structured edit operation(s) to \(authorized.presentationPath)",
            estimatedWriteCount: decoded.operations.isEmpty ? 0 : 1,
            sideEffects: risk.defaultSideEffects,
            rootIDs: [
                decoded.rootID.rawValue
            ],
            capabilitiesRequired: [
                .write
            ],
            estimatedChangedLineCount: preview.changeCount,
            isPreview: true,
            policyChecks: [
                "workspace_required",
                "root_path_authorized",
                "edit_operations_decoded",
                "difference_preview_generated"
            ],
            diffPreview: diffPreview
        )
    }

    public func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        let workspace = try FileToolSupport.requireWorkspace(
            workspace,
            toolName: name
        )

        let decoded = try JSONToolBridge.decode(
            EditFileToolInput.self,
            from: input
        )

        let authorized = try FileToolAccess.authorize(
            workspace: workspace,
            rootID: decoded.rootID,
            path: decoded.path,
            capability: .write,
            toolName: name,
            type: .file
        )

        let editor = FileEditor(
            workspace: workspace
        )

        let operations = try decoded.operations.map { operation in
            try operation.standardOperation()
        }

        let preview = try editor.previewEdit(
            operations,
            at: authorized.scopedPath
        )

        let mutationContext = AgentFileMutationContext(
            rootID: authorized.rootID,
            toolCallID: context.toolCallID,
            preparedIntentID: context.preparedIntentID,
            metadata: mutationMetadata(
                authorized: authorized,
                context: context
            )
        )

        let edit: (result: StandardEditResult, mutation: AgentFileMutationToolSummary?)

        if let recorder {
            let recorded = try await editor.editRecorded(
                operations,
                at: authorized.scopedPath,
                recorder: recorder,
                options: .init(
                    mutation: mutationContext
                )
            )

            edit = (
                try editResult(
                    from: recorded
                ),
                .init(
                    result: recorded,
                    policy: recorder.policy
                )
            )
        } else {
            edit = (
                try editor.edit(
                    operations,
                    at: authorized.scopedPath
                ),
                nil
            )
        }

        return try JSONToolBridge.encode(
            EditFileToolOutput(
                rootID: authorized.rootID.rawValue,
                path: authorized.presentationPath,
                operationCount: operations.count,
                changeCount: preview.changeCount,
                diffSummary: .init(
                    insertedLineCount: edit.result.insertions,
                    deletedLineCount: edit.result.deletions
                ),
                originalChangedLineRanges: preview.originalChangedLineRanges,
                editedChangedLineRanges: preview.editedChangedLineRanges,
                mutation: edit.mutation
            )
        )
    }

    public func call(
        input: JSONValue,
        context: AgentToolExecutionContext
    ) async throws -> JSONValue {
        let decoded = try JSONToolBridge.decode(
            EditFileToolInput.self,
            from: input
        )

        return try await call(
            decoded,
            context: context
        )
    }

    public func call(
        _ input: EditFileToolInput,
        context: AgentToolExecutionContext
    ) async throws -> JSONValue {
        let tool = Self(
            recorder: recorder,
            context: mergedMutationContext(
                toolContext: context,
                action: "edit"
            )
        )

        return try await tool.call(
            input: try JSONToolBridge.encode(
                input
            ),
            workspace: context.workspace
        )
    }

    private func mergedMutationContext(
        toolContext: AgentToolExecutionContext,
        action: String
    ) -> AgentFileMutationContext {
        if self.context == .empty {
            return .init(
                toolContext: toolContext,
                additionalMetadata: [
                    "toolName": Self.identifier.rawValue,
                    "intent_action": action,
                    "intent_action_type": FileMutationIntentAction.edit.actionType
                ]
            )
        }

        var mutationContext = self.context

        if mutationContext.toolCallID == nil {
            mutationContext.toolCallID = toolContext.toolCallID
        }

        if mutationContext.preparedIntentID == nil {
            mutationContext.preparedIntentID = toolContext.preparedIntentID
        }

        mutationContext.metadata.merge(
            toolContext.metadata
        ) { old, _ in
            old
        }

        mutationContext.metadata["toolName"] = Self.identifier.rawValue
        mutationContext.metadata["intent_action"] = action
        mutationContext.metadata["intent_action_type"] = FileMutationIntentAction.edit.actionType
        mutationContext.metadata["execution_mode"] = toolContext.executionMode.rawValue

        return mutationContext
    }
}

private extension EditFileTool {
    func previewOriginalText(
        at url: URL
    ) -> String {
        (
            try? TextFileReader(
                url
            ).read(
                options: .init(
                    decoding: .commonTextFallbacks,
                    missingFilePolicy: .returnEmpty,
                    newlineNormalization: .unix
                )
            ).text
        ) ?? ""
    }
    func makeDiffPreview(
        authorized: AgenticAuthorizedPath,
        preview: StandardEditResult,
        operationCount: Int
    ) -> ToolPreflightDiffPreview {
        let contextLineCount = 3
        let original = previewOriginalText(
            at: authorized.absoluteURL
        )
        let edited = preview.editedContent

        let difference = TextDiffer.diff(
            old: original,
            new: edited,
            oldName: "a/\(authorized.presentationPath)",
            newName: "b/\(authorized.presentationPath)"
        )

        let options = DifferenceRenderOptions(
            showHeader: true,
            showUnchangedLines: false,
            contextLineCount: contextLineCount
        )

        let layout = DifferenceRenderer.layout(
            difference,
            options: options
        )

        let rendered = difference.hasChanges
            ? DifferenceRenderer.render(
                layout,
                options: options
            )
            : """
            --- a/\(authorized.presentationPath)
            +++ b/\(authorized.presentationPath)
            # no textual changes
            """

        return .init(
            title: "Preview diff for \(authorized.presentationPath)",
            contextLineCount: contextLineCount,
            text: rendered,
            layout: layout,
            insertedLineCount: difference.insertions,
            deletedLineCount: difference.deletions
        )
    }

    func renderLineRanges(
        _ ranges: [LineRange]
    ) -> String {
        guard !ranges.isEmpty else {
            return "none"
        }

        return ranges.map { range in
            "\(range.start)-\(range.end)"
        }
        .joined(separator: ", ")
    }

    func mutationMetadata(
        authorized: AgenticAuthorizedPath,
        context: AgentFileMutationContext
    ) -> [String: String] {
        var metadata = [
            "tool_name": name,
            "root_id": authorized.rootID.rawValue,
            "path": authorized.presentationPath
        ]

        for (key, value) in context.metadata {
            metadata[key] = value
        }

        return metadata
    }

    func editResult(
        from result: AgentFileMutationResult
    ) throws -> StandardEditResult {
        guard let editResult = result.editResult else {
            throw PredefinedFileToolError.invalidValue(
                tool: name,
                field: "recorder",
                reason: "recorded mutation result did not include an edit result"
            )
        }

        return editResult
    }
}
