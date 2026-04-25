import Difference
import Foundation
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

        let byteCount = decoded.content.utf8.count
        let diffPreview = makeDiffPreview(
            authorized: authorized,
            replacement: decoded.content,
            contextLineCount: 3
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace.rootURL.path,
            targetPaths: [
                authorized.presentationPath
            ],
            summary: "Replace entire file contents at \(authorized.presentationPath)",
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
            estimatedChangedLineCount: diffPreview.changedLineCount,
            isPreview: true,
            policyChecks: [
                "workspace_required",
                "root_path_authorized",
                "write_budget_estimated",
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

private extension WriteFileTool {
    func makeDiffPreview(
        authorized: AgenticAuthorizedPath,
        replacement: String,
        contextLineCount: Int
    ) -> ToolPreflightDiffPreview {
        let original = readExistingText(
            at: authorized.absoluteURL
        )

        let difference = TextDiffer.diff(
            old: original,
            new: replacement,
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

    func readExistingText(
        at url: URL
    ) -> String {
        guard FileManager.default.fileExists(
            atPath: url.path
        ) else {
            return ""
        }

        return (
            try? String(
                contentsOf: url,
                encoding: .utf8
            )
        ) ?? ""
    }
}
