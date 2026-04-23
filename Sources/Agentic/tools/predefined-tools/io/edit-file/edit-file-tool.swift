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

        let targetPath: String
        if let workspace {
            targetPath = try workspace.resolve(
                decoded.path
            ).presentingRelative(
                filetype: true
            )
        } else {
            targetPath = decoded.path
        }

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            targetPaths: [targetPath],
            summary: "Apply \(decoded.operations.count) structured edit operation(s) to \(targetPath)",
            estimatedWriteCount: decoded.operations.isEmpty ? 0 : 1,
            sideEffects: risk.defaultSideEffects
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

        let editor = FileEditor(
            workspace: workspace
        )

        let scopedPath = try workspace.resolve(
            decoded.path
        )

        let operations = try decoded.operations.map { operation in
            try operation.standardOperation()
        }

        let preview = try editor.previewEdit(
            operations,
            at: scopedPath
        )

        let result = try editor.edit(
            operations,
            at: scopedPath
        )

        return try JSONToolBridge.encode(
            EditFileToolOutput(
                path: scopedPath.presentingRelative(
                    filetype: true
                ),
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
