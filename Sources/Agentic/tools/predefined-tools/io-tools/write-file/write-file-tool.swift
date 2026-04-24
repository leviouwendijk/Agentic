import Primitives

public struct WriteFileTool: AgentTool {
    public static let identifier: AgentToolIdentifier = "write_file"
    public static let description = "Replace the entire contents of a file in the workspace."
    public static let risk: ActionRisk = .boundedmutate

    public init() {}

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let decoded = try JSONToolBridge.decode(
            WriteFileToolInput.self,
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
            summary: "Replace entire file contents at \(targetPath)",
            estimatedWriteCount: 1,
            estimatedByteCount: decoded.content.utf8.count,
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
            WriteFileToolInput.self,
            from: input
        )

        let editor = FileEditor(
            workspace: workspace
        )

        let scopedPath = try workspace.resolve(
            decoded.path
        )

        let result = try editor.write(
            decoded.content,
            to: scopedPath
        )

        return try JSONToolBridge.encode(
            WriteFileToolOutput(
                path: scopedPath.presentingRelative(
                    filetype: true
                ),
                bytesWritten: result.writeResult?.bytesWritten ?? 0,
                diffSummary: .init(
                    insertedLineCount: result.insertions,
                    deletedLineCount: result.deletions
                ),
                changeCount: result.changeCount,
                originalChangedLineRanges: result.originalChangedLineRanges,
                editedChangedLineRanges: result.editedChangedLineRanges
            )
        )
    }
}
