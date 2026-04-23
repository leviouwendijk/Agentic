import Primitives
import Writers

public struct EditFileTool: AgentTool {
    public let definition: AgentToolDefinition

    public var actionRisk: ActionRisk {
        .boundedmutate
    }

    public init() {
        self.definition = .init(
            name: "edit_file",
            description: "Apply one or more structured edit operations to a file in the workspace."
        )
    }

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let decoded = try JSONToolBridge.decode(
            EditFileToolInput.self,
            from: input
        )

        return .init(
            toolName: definition.name,
            actionRisk: actionRisk,
            workspaceRoot: workspace?.rootURL.path,
            targetPaths: [decoded.path],
            summary: "Apply \(decoded.operations.count) structured edit operation(s) to \(decoded.path)",
            estimatedWriteCount: decoded.operations.isEmpty ? 0 : 1,
            sideEffects: actionRisk.defaultSideEffects
        )
    }

    public func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        let workspace = try FileToolSupport.requireWorkspace(
            workspace,
            toolName: definition.name
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
