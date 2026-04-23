import Primitives

public struct WriteFileTool: AgentTool {
    public let definition: AgentToolDefinition

    public var actionRisk: ActionRisk {
        .boundedmutate
    }

    public init() {
        self.definition = .init(
            name: "write_file",
            description: "Replace the entire contents of a file in the workspace."
        )
    }

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let decoded = try JSONToolBridge.decode(
            WriteFileToolInput.self,
            from: input
        )

        return .init(
            toolName: definition.name,
            actionRisk: actionRisk,
            workspaceRoot: workspace?.rootURL.path,
            targetPaths: [decoded.path],
            summary: "Replace entire file contents at \(decoded.path)",
            estimatedWriteCount: 1,
            estimatedByteCount: decoded.content.utf8.count,
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
