import Primitives

public struct ReadFileTool: AgentTool {
    public let definition: AgentToolDefinition

    public var actionRisk: ActionRisk {
        .observe
    }

    public init() {
        self.definition = .init(
            name: "read_file",
            description: "Read a file from the workspace, optionally constrained to a line window."
        )
    }

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

        return .init(
            toolName: definition.name,
            actionRisk: actionRisk,
            workspaceRoot: workspace?.rootURL.path,
            targetPaths: [decoded.path],
            summary: summary(for: decoded)
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
        for input: ReadFileToolInput
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
            return "Read file \(input.path)"
        }

        return "Read file \(input.path) (\(parts.joined(separator: ", ")))"
    }
}
