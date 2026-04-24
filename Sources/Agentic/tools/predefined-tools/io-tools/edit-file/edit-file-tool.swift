import Primitives
import Writers

public struct EditFileTool: AgentTool {
    public static let identifier: AgentToolIdentifier = "edit_file"
    public static let description = "Apply one or more structured edit operations to a file in the workspace."
    public static let risk: ActionRisk = .boundedmutate

    public init() {}

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let decoded = try JSONToolBridge.decode(
            EditFileToolInput.self,
            from: input
        )

        let targetPath = try FileToolAccess.presentationPath(
            workspace: workspace,
            rootID: decoded.rootID,
            path: decoded.path,
            type: .file
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            targetPaths: [
                targetPath
            ],
            summary: "Apply \(decoded.operations.count) structured edit operation(s) to \(targetPath)",
            estimatedWriteCount: decoded.operations.isEmpty ? 0 : 1,
            sideEffects: risk.defaultSideEffects,
            rootIDs: [
                decoded.rootID.rawValue
            ],
            capabilitiesRequired: [
                .write
            ],
            estimatedChangedLineCount: decoded.operations.count,
            isPreview: false,
            policyChecks: [
                "workspace_required",
                "root_path_resolved",
                "edit_operations_decoded"
            ]
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

        let result = try editor.edit(
            operations,
            at: authorized.scopedPath
        )

        return try JSONToolBridge.encode(
            EditFileToolOutput(
                rootID: authorized.rootID.rawValue,
                path: authorized.presentationPath,
                operationCount: operations.count,
                changeCount: preview.changeCount,
                diffSummary: .init(
                    insertedLineCount: result.insertions,
                    deletedLineCount: result.deletions
                ),
                originalChangedLineRanges: preview.originalChangedLineRanges,
                editedChangedLineRanges: preview.editedChangedLineRanges
            )
        )
    }
}
