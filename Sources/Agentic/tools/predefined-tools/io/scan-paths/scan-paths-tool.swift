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

        let targetPaths: [String]
        if let path = decoded.path?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !path.isEmpty,
           path != "." {
            targetPaths = [path]
        } else {
            targetPaths = []
        }

        let summary: String
        if let target = targetPaths.first {
            summary = decoded.recursive
                ? "Recursively scan \(target)"
                : "Scan direct entries in \(target)"
        } else {
            summary = decoded.recursive
                ? "Recursively scan workspace root"
                : "Scan direct entries in workspace root"
        }

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

        let trimmedPath = decoded.path?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let directory: ScopedPath?
        if let trimmedPath,
           !trimmedPath.isEmpty,
           trimmedPath != "." {
            directory = try workspace.resolve(
                trimmedPath
            )
        } else {
            directory = nil
        }

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
