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

        let targetPath = try FileToolAccess.presentationPath(
            workspace: workspace,
            rootID: decoded.rootID,
            path: decoded.path,
            type: .file
        )

        let byteCount = decoded.content.utf8.count

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            targetPaths: [
                targetPath
            ],
            summary: "Replace entire file contents at \(targetPath)",
            estimatedWriteCount: 1,
            estimatedByteCount: byteCount,
            sideEffects: risk.defaultSideEffects,
            rootIDs: [
                decoded.rootID.rawValue
            ],
            capabilitiesRequired: [
                .write
            ],
            estimatedWriteBytes: byteCount,
            isPreview: false,
            policyChecks: [
                "workspace_required",
                "root_path_resolved",
                "write_budget_estimated"
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
            WriteFileToolInput.self,
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

        let result = try editor.write(
            decoded.content,
            to: authorized.scopedPath
        )

        return try JSONToolBridge.encode(
            WriteFileToolOutput(
                rootID: authorized.rootID.rawValue,
                path: authorized.presentationPath,
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
