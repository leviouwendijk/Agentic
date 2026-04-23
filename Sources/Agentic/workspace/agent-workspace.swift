import Foundation
import Path
import Position
import Readers
import FileTypes
import Selection

public struct AgentWorkspace: Sendable, Equatable {
    public let sandbox: PathSandbox
    public let accessPolicy: PathAccessPolicy

    public init(
        root: StandardPath,
        accessPolicy: PathAccessPolicy = .agenticWorkspaceDefault
    ) throws {
        self.sandbox = try .init(root: root)
        self.accessPolicy = accessPolicy
    }

    public init(
        root: URL,
        accessPolicy: PathAccessPolicy = .agenticWorkspaceDefault
    ) throws {
        try self.init(
            root: StandardPath(
                fileURL: root,
                terminalHint: .directory,
                inferFileType: false
            ),
            accessPolicy: accessPolicy
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

    public func evaluateAccess(
        _ path: ScopedPath,
        type: PathSegmentType? = nil
    ) -> PathAccessEvaluation {
        accessPolicy.evaluate(
            path,
            type: type
        )
    }

    @discardableResult
    public func requireAccessible(
        _ path: ScopedPath,
        type: PathSegmentType? = nil
    ) throws -> ScopedPath {
        guard sandbox.contains(path) else {
            throw PathSandboxError.pathEscapesSandbox(
                path: path.absolute,
                root: root
            )
        }

        let evaluation = accessPolicy.evaluate(
            path,
            type: type
        )

        guard evaluation.isAllowed else {
            throw PathAccessError.denied(evaluation)
        }

        return path
    }

    public func resolve(
        _ path: StandardPath
    ) throws -> ScopedPath {
        try sandbox.sandbox(
            path,
            policy: accessPolicy,
            type: inferredType(for: path)
        )
    }

    public func resolve(
        _ rawPath: String,
        filetype: AnyFileType? = nil
    ) throws -> ScopedPath {
        let scoped = try sandbox.sandbox(
            rawPath: rawPath,
            filetype: filetype
        )

        return try requireAccessible(
            scoped,
            type: hintedType(
                rawPath: rawPath,
                filetype: filetype,
                resolved: scoped
            )
        )
    }

    public func scope(
        _ url: URL
    ) throws -> ScopedPath {
        let existence = PathExistence.check(
            url: url
        )
        let type = existence.1
        let terminalHint = terminalHint(
            for: type
        )

        let path = StandardPath(
            fileURL: url,
            terminalHint: terminalHint,
            inferFileType: type == .file
        )

        return try sandbox.sandbox(
            path,
            policy: accessPolicy,
            type: type
        )
    }

    public func contains(
        _ path: ScopedPath
    ) -> Bool {
        (try? requireAccessible(path)) != nil
    }

    public func contains(
        _ path: StandardPath
    ) -> Bool {
        (try? resolve(path)) != nil
    }

    public func absoluteURL(
        for path: ScopedPath
    ) throws -> URL {
        let path = try requireAccessible(path)

        return absoluteURLUnchecked(
            for: path
        )
    }

    public func existingType(
        of path: ScopedPath
    ) throws -> PathSegmentType? {
        let url = try absoluteURL(
            for: path
        )
        return PathExistence.check(
            url: url
        ).1
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
        let path = try requireAccessible(
            path,
            type: .file
        )
        let result = try TextFileReader(
            absoluteURLUnchecked(for: path)
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
        let path = try requireAccessible(
            path,
            type: .file
        )
        let result = try LineReader(
            absoluteURLUnchecked(for: path)
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
        let path = try requireAccessible(
            path,
            type: .file
        )
        let result = try LineReader(
            absoluteURLUnchecked(for: path)
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
        let path = try requireAccessible(
            path,
            type: .file
        )
        let result = try LineReader(
            absoluteURLUnchecked(for: path)
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
        let path = try requireAccessible(
            path,
            type: .file
        )
        let result = try DataFileReader(
            absoluteURLUnchecked(for: path)
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
        let path = try requireAccessible(
            path,
            type: .file
        )
        let result = try DataFileReader(
            absoluteURLUnchecked(for: path)
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
        let path = try requireAccessible(
            path,
            type: .file
        )
        let url = absoluteURLUnchecked(
            for: path
        )
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
        let result = try PathScan.scan(
            specification,
            relativeTo: .directoryURL(rootURL),
            configuration: configuration
        )

        return .init(
            matches: filteredMatches(
                from: result
            ),
            warnings: result.warnings
        )
    }

    public func scopedEntries(
        from result: PathScanResult,
        excluding scannedPath: ScopedPath? = nil
    ) -> [ScopedWorkspaceScan.Entry] {
        result.matches.compactMap { match in
            guard let relative = sandbox.tree.relative(
                match.path
            ) else {
                return nil
            }

            guard !relative.segments.isEmpty else {
                return nil
            }

            if let scannedPath,
               relative == scannedPath.relative {
                return nil
            }

            let scoped = ScopedPath(
                root: root,
                relative: relative
            )

            guard (try? requireAccessible(
                scoped,
                type: match.type
            )) != nil else {
                return nil
            }

            return .init(
                path: scoped,
                isDirectory: match.type == .directory
            )
        }
    }
}

private extension AgentWorkspace {
    func absoluteURLUnchecked(
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

    func filteredMatches(
        from result: PathScanResult
    ) -> [PathScanMatch] {
        result.matches.filter { match in
            guard let relative = sandbox.tree.relative(
                match.path
            ) else {
                return false
            }

            let scoped = ScopedPath(
                root: root,
                relative: relative
            )

            return accessPolicy.allows(
                scoped,
                type: match.type
            )
        }
    }

    func inferredType(
        for path: StandardPath
    ) -> PathSegmentType? {
        if path.filetype != nil {
            return .file
        }

        return nil
    }

    func hintedType(
        rawPath: String,
        filetype: AnyFileType?,
        resolved: ScopedPath
    ) -> PathSegmentType? {
        if filetype != nil {
            return .file
        }

        let trimmed = rawPath.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if trimmed.hasSuffix("/") {
            return .directory
        }

        if resolved.relative.filetype != nil {
            return .file
        }

        return nil
    }

    func terminalHint(
        for type: PathSegmentType?
    ) -> PathTerminalHint {
        switch type {
        case .file?:
            return .file

        case .directory?:
            return .directory

        case nil:
            return .unspecified
        }
    }
}
