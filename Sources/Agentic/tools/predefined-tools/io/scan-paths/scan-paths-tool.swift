import Primitives
import Path
import PathParsing

public struct ScanPathsTool: AgentTool {
    public let definition: AgentToolDefinition

    public var actionRisk: ActionRisk {
        .observe
    }

    public init() {
        self.definition = .init(
            name: "scan_paths",
            description: "Scan paths inside the workspace using PathScan."
        )
    }

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let decoded = try JSONToolBridge.decode(
            ScanPathsToolInput.self,
            from: input
        )

        let directory = try resolvedDirectory(
            from: decoded,
            workspace: workspace
        )

        let targetPaths: [String]
        if let directory {
            targetPaths = [
                directory.presentingRelative(
                    filetype: true
                )
            ]
        } else {
            targetPaths = []
        }

        let summary = summary(
            for: decoded,
            directory: directory
        )

        return .init(
            toolName: definition.name,
            actionRisk: actionRisk,
            workspaceRoot: workspace?.rootURL.path,
            targetPaths: targetPaths,
            summary: decoded.excludes.isEmpty
                ? summary
                : "\(summary) with \(decoded.excludes.count) exclude pattern(s)"
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
            ScanPathsToolInput.self,
            from: input
        )

        let directory = try resolvedDirectory(
            from: decoded,
            workspace: workspace
        )

        let includeRaw: String
        if let directory {
            includeRaw = "\(directory.presentingRelative(filetype: true))/**"
        } else {
            includeRaw = "**"
        }

        let specification = try ParsedPathScan.specification(
            includes: [includeRaw],
            excludes: decoded.excludes
        )

        let result = try workspace.scan(
            specification,
            configuration: .init(
                maxDepth: decoded.recursive ? nil : 1,
                includeHidden: decoded.includeHidden,
                followSymlinks: decoded.followSymlinks,
                emitDirectories: decoded.includeDirectories,
                emitFiles: decoded.includeFiles
            )
        )

        var entries = workspace.scopedEntries(
            from: result,
            excluding: directory
        )

        let truncated: Bool
        if let maxEntries = decoded.maxEntries,
           maxEntries >= 0,
           entries.count > maxEntries {
            entries = Array(
                entries.prefix(maxEntries)
            )
            truncated = true
        } else {
            truncated = false
        }

        return try JSONToolBridge.encode(
            ScanPathsToolOutput(
                directory: directory?.presentingRelative(
                    filetype: true
                ),
                entries: entries.map { entry in
                    .init(
                        path: entry.relativePath,
                        isDirectory: entry.isDirectory
                    )
                },
                truncated: truncated
            )
        )
    }
}

private extension ScanPathsTool {
    func resolvedDirectory(
        from input: ScanPathsToolInput,
        workspace: AgentWorkspace?
    ) throws -> ScopedPath? {
        guard let trimmedPath = input.path?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !trimmedPath.isEmpty,
            trimmedPath != "." else {
            return nil
        }

        guard let workspace else {
            return nil
        }

        let scoped = try workspace.resolve(
            trimmedPath
        )

        if try workspace.existingType(
            of: scoped
        ) == .file {
            throw PredefinedFileToolError.invalidValue(
                tool: "scan_paths",
                field: "path",
                reason: "must reference a directory, not a file"
            )
        }

        return scoped
    }

    func summary(
        for input: ScanPathsToolInput,
        directory: ScopedPath?
    ) -> String {
        if let directory {
            return input.recursive
                ? "Recursively scan \(directory.presentingRelative(filetype: true))"
                : "Scan direct entries in \(directory.presentingRelative(filetype: true))"
        }

        return input.recursive
            ? "Recursively scan workspace root"
            : "Scan direct entries in workspace root"
    }
}
