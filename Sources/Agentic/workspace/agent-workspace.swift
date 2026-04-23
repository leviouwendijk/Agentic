import Foundation
import Path
import Position
import Readers
import FileTypes
import Selection

public struct AgentWorkspace: Sendable, Equatable {
    public let sandbox: PathSandbox

    public init(
        root: StandardPath
    ) throws {
        self.sandbox = try .init(root: root)
    }

    public init(
        root: URL
    ) throws {
        try self.init(
            root: StandardPath(
                fileURL: root,
                terminalHint: .directory,
                inferFileType: false
            )
        )
    }

    public var root: StandardPath {
        sandbox.root
    }

    public var rootURL: URL {
        URL(
            fileURLWithPath: root.render(
                as: .root,
                filetype: false
            ),
            isDirectory: true
        ).standardizedFileURL
    }

    public func resolve(
        _ path: StandardPath
    ) throws -> ScopedPath {
        try sandbox.sandbox(path)
    }

    public func resolve(
        _ rawPath: String,
        filetype: AnyFileType? = nil
    ) throws -> ScopedPath {
        try sandbox.sandbox(
            rawPath: rawPath,
            filetype: filetype
        )
    }

    public func contains(
        _ path: ScopedPath
    ) -> Bool {
        sandbox.contains(path)
    }

    public func absoluteURL(
        for path: ScopedPath
    ) -> URL {
        URL(
            fileURLWithPath: path.absolute.render(
                as: .root,
                filetype: true
            ),
            isDirectory: path.relative.filetype == nil
        ).standardizedFileURL
    }

    public func read(
        _ path: ScopedPath,
        encoding: String.Encoding = .utf8
    ) throws -> ScopedWorkspaceRead {
        try read(
            path,
            options: .init(
                decoding: .exact(
                    .init(encoding)
                ),
                missingFilePolicy: .throwError,
                newlineNormalization: .unix
            )
        )
    }

    public func read(
        _ path: ScopedPath,
        options: TextReadOptions = .init(
            decoding: .commonTextFallbacks,
            missingFilePolicy: .throwError,
            newlineNormalization: .unix
        )
    ) throws -> ScopedWorkspaceRead {
        let result = try TextFileReader(
            absoluteURL(for: path)
        ).read(
            options: options
        )

        return .init(
            path: path,
            text: result.text,
            encodingUsed: result.encodingUsed,
            byteCount: result.byteCount,
            existed: result.existed
        )
    }

    public func readLines(
        _ path: ScopedPath,
        options: LineReadOptions = .default
    ) throws -> ScopedWorkspaceLineRead {
        let result = try LineReader(
            absoluteURL(for: path)
        ).read(
            options: options
        )

        return .init(
            path: path,
            lines: result.lines,
            encodingUsed: result.encodingUsed,
            byteCount: result.byteCount,
            existed: result.existed
        )
    }

    public func readSlice(
        _ path: ScopedPath,
        range: LineRange?,
        maxLines: Int? = nil,
        options: LineReadOptions = .default
    ) throws -> ScopedWorkspaceLineSliceRead {
        let result = try LineReader(
            absoluteURL(for: path)
        ).readSlice(
            range: range,
            maxLines: maxLines,
            options: options
        )

        return .init(
            path: path,
            selectedLines: result.selectedLines,
            selectedLineRange: result.selectedLineRange,
            totalLineCount: result.totalLineCount,
            truncated: result.truncated,
            encodingUsed: result.encodingUsed,
            byteCount: result.byteCount,
            existed: result.existed
        )
    }

    public func readSlice(
        _ path: ScopedPath,
        startLine: Int? = nil,
        endLine: Int? = nil,
        maxLines: Int? = nil,
        options: LineReadOptions = .default
    ) throws -> ScopedWorkspaceLineSliceRead {
        let result = try LineReader(
            absoluteURL(for: path)
        ).readSlice(
            startLine: startLine,
            endLine: endLine,
            maxLines: maxLines,
            options: options
        )

        return .init(
            path: path,
            selectedLines: result.selectedLines,
            selectedLineRange: result.selectedLineRange,
            totalLineCount: result.totalLineCount,
            truncated: result.truncated,
            encodingUsed: result.encodingUsed,
            byteCount: result.byteCount,
            existed: result.existed
        )
    }

    public func readData(
        _ path: ScopedPath,
        options: DataReadOptions = .default
    ) throws -> ScopedWorkspaceDataRead {
        let result = try DataFileReader(
            absoluteURL(for: path)
        ).read(
            options: options
        )

        return .init(
            path: path,
            data: result.data,
            byteCount: result.byteCount,
            existed: result.existed
        )
    }

    public func readBase64(
        _ path: ScopedPath,
        options: DataReadOptions = .default
    ) throws -> ScopedWorkspaceBase64Read {
        let result = try DataFileReader(
            absoluteURL(for: path)
        ).readBase64(
            options: options
        )

        return .init(
            path: path,
            base64: result.base64,
            mediaType: result.mediaType,
            byteCount: result.byteCount,
            existed: result.existed
        )
    }

    public func readSelection(
        _ path: ScopedPath,
        _ selection: ContentSelection,
        options: LineReadOptions = .default
    ) throws -> ScopedWorkspaceSelectionRead {
        try readSelections(
            path,
            [selection],
            options: options
        )
    }

    public func readSelections(
        _ path: ScopedPath,
        _ selections: [ContentSelection],
        options: LineReadOptions = .default
    ) throws -> ScopedWorkspaceSelectionRead {
        let url = absoluteURL(for: path)
        let readResult = try LineReader(url).read(
            options: options
        )
        let resolved = SelectionResolver.resolve(
            file: url,
            readResult: readResult,
            selections: selections
        )

        return .init(
            path: path,
            resolved: resolved
        )
    }

    public func scan(
        _ specification: PathScanSpecification,
        configuration: PathWalkConfiguration = .init()
    ) throws -> PathScanResult {
        try PathScan.scan(
            specification,
            relativeTo: .directoryURL(rootURL),
            configuration: configuration
        )
    }

    public func scopedEntries(
        from result: PathScanResult,
        excluding scannedPath: ScopedPath? = nil
    ) -> [ScopedWorkspaceScan.Entry] {
        let tree = PathTree(root: root)

        return result.matches.compactMap { match in
            guard let relative = tree.relative(match.path) else {
                return nil
            }

            guard !relative.segments.isEmpty else {
                return nil
            }

            if let scannedPath,
               relative == scannedPath.relative {
                return nil
            }

            return .init(
                path: .init(
                    root: root,
                    relative: relative
                ),
                isDirectory: match.path.filetype == nil
            )
        }
    }
}
