import Primitives

public struct ReadFileTool: AgentTool {
    public static let identifier: AgentToolIdentifier = "read_file"
    public static let description = "Read a file from the workspace, optionally constrained to a line window."
    public static let risk: ActionRisk = .observe

    public init() {}

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let decoded = try JSONToolBridge.decode(
            ReadFileToolInput.self,
            from: input
        )

        try FileToolSupport.validateReadWindow(
            startLine: decoded.startLine,
            endLine: decoded.endLine,
            maxLines: decoded.maxLines
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
            summary: summary(
                for: decoded,
                renderedPath: targetPath
            )
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
            ReadFileToolInput.self,
            from: input
        )

        try FileToolSupport.validateReadWindow(
            startLine: decoded.startLine,
            endLine: decoded.endLine,
            maxLines: decoded.maxLines
        )

        let scopedPath = try workspace.resolve(
            decoded.path
        )

        let read = try workspace.readSlice(
            scopedPath,
            startLine: decoded.startLine,
            endLine: decoded.endLine,
            maxLines: decoded.maxLines
        )

        let renderedContent: String
        if let range = read.selectedLineRange {
            renderedContent = FileToolSupport.renderLines(
                read.selectedLines,
                startingAt: range.start,
                includeLineNumbers: decoded.includeLineNumbers
            )
        } else {
            renderedContent = ""
        }

        return try JSONToolBridge.encode(
            ReadFileToolOutput(
                path: read.relativePath,
                content: renderedContent,
                lineRange: read.selectedLineRange,
                lineCount: read.lineCount,
                totalLineCount: read.totalLineCount,
                byteCount: read.byteCount,
                truncated: read.truncated,
                encoding: read.encodingUsed?.name
            )
        )
    }
}

private extension ReadFileTool {
    func summary(
        for input: ReadFileToolInput,
        renderedPath: String
    ) -> String {
        var parts: [String] = []

        if let startLine = input.startLine,
           let endLine = input.endLine {
            parts.append("lines \(startLine)-\(endLine)")
        } else if let startLine = input.startLine {
            parts.append("starting at line \(startLine)")
        } else if let endLine = input.endLine {
            parts.append("through line \(endLine)")
        }

        if let maxLines = input.maxLines {
            parts.append("max \(maxLines) line(s)")
        }

        if input.includeLineNumbers {
            parts.append("with line numbers")
        }

        guard !parts.isEmpty else {
            return "Read file \(renderedPath)"
        }

        return "Read file \(renderedPath) (\(parts.joined(separator: ", ")))"
    }
}
