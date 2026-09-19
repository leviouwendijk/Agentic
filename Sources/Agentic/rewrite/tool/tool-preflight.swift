import Difference
import Foundation
import Workspace

public struct ToolPreflight:
    Sendable,
    Codable,
    Hashable,
    CustomStringConvertible
{
    public let tool: ToolIdentifier
    public let risk: ActionRisk
    public let summary: String

    public let access: Access
    public let estimates: Estimates
    public let preview: Preview

    public let sideEffects: [String]
    public let policyChecks: [String]
    public let warnings: [String]

    public init(
        tool: ToolIdentifier,
        risk: ActionRisk,
        summary: String,
        access: Access = .none,
        estimates: Estimates = .none,
        preview: Preview = .none,
        sideEffects: [String] = [],
        policyChecks: [String] = [],
        warnings: [String] = []
    ) {
        self.tool = tool
        self.risk = risk
        self.summary = summary
        self.access = access
        self.estimates = estimates
        self.preview = preview
        self.sideEffects = sideEffects
        self.policyChecks = policyChecks
        self.warnings = warnings
    }

    public var description: String {
        var lines = [
            "tool: \(tool.rawValue)",
            "risk: \(risk.rawValue)",
            "summary: \(summary)",
        ]

        if !access.roots.isEmpty {
            lines.append(
                "roots: \(access.roots.joined(separator: ", "))"
            )
        }

        if !access.capabilities.isEmpty {
            lines.append(
                "capabilities: \(access.capabilities.map(\.rawValue).joined(separator: ", "))"
            )
        }

        if !access.targets.isEmpty {
            lines.append(
                "targets: \(access.targets.joined(separator: ", "))"
            )
        }

        if access.includesHidden {
            lines.append(
                "includes hidden paths"
            )
        }

        if access.followsSymlinks {
            lines.append(
                "follows symlinks"
            )
        }

        if let command = preview.command {
            lines.append(
                "command: \(command)"
            )
        }

        if let difference = preview.difference {
            lines.append(
                "diff preview: \(difference.layout.changes.insertions.count) insertions, \(difference.layout.changes.deletions.count) deletions"
            )
        }

        if estimates.write.count > 0 {
            lines.append(
                "estimated writes: \(estimates.write.count)"
            )
        }

        if let bytes = estimates.maximumByteCount {
            lines.append(
                "estimated bytes: \(bytes)"
            )
        }

        if let entries = estimates.scan.entries {
            lines.append(
                "estimated scan entries: \(entries)"
            )
        }

        if let readLines = estimates.read.lines {
            lines.append(
                "estimated read lines: \(readLines)"
            )
        }

        if let runtime = estimates.runtime {
            lines.append(
                "estimated runtime: \(runtime)s"
            )
        }

        if !policyChecks.isEmpty {
            lines.append(
                "policy checks: \(policyChecks.joined(separator: ", "))"
            )
        }

        if !warnings.isEmpty {
            lines.append(
                "warnings: \(warnings.joined(separator: ", "))"
            )
        }

        if !sideEffects.isEmpty {
            lines.append(
                "side effects: \(sideEffects.joined(separator: ", "))"
            )
        }

        return lines.joined(
            separator: "\n"
        )
    }
}

public extension ToolPreflight {
    struct Access:
        Sendable,
        Codable,
        Hashable
    {
        public let targets: [String]
        public let roots: [String]
        public let capabilities: [WorkspaceCapability]
        public let includesHidden: Bool
        public let followsSymlinks: Bool

        public init(
            targets: [String] = [],
            roots: [String] = [],
            capabilities: [WorkspaceCapability] = [],
            includesHidden: Bool = false,
            followsSymlinks: Bool = false
        ) {
            self.targets = targets
            self.roots = roots
            self.capabilities = capabilities
            self.includesHidden = includesHidden
            self.followsSymlinks = followsSymlinks
        }

        public static let none = Self()

        public var hasFilesystemAccess: Bool {
            !targets.isEmpty
            || !roots.isEmpty
            || !capabilities.isEmpty
        }
    }

    struct Estimates:
        Sendable,
        Codable,
        Hashable
    {
        public let scan: Scan
        public let read: Read
        public let write: Write
        public let context: Context

        public let runtime: TimeInterval?
        public let bytes: Int?
        public let outputBytes: Int?

        public init(
            scan: Scan = .none,
            read: Read = .none,
            write: Write = .none,
            context: Context = .none,
            runtime: TimeInterval? = nil,
            bytes: Int? = nil,
            outputBytes: Int? = nil
        ) {
            self.scan = scan
            self.read = read
            self.write = write
            self.context = context
            self.runtime = runtime
            self.bytes = bytes
            self.outputBytes = outputBytes
        }

        public static let none = Self()

        public var maximumByteCount: Int? {
            [
                bytes,
                read.bytes,
                write.bytes,
                outputBytes,
                context.bytes,
            ]
            .compactMap {
                $0
            }
            .max()
        }

        public struct Scan:
            Sendable,
            Codable,
            Hashable
        {
            public let entries: Int?
            public let depth: Int?

            public init(
                entries: Int? = nil,
                depth: Int? = nil
            ) {
                self.entries = entries
                self.depth = depth
            }

            public static let none = Self()
        }

        public struct Read:
            Sendable,
            Codable,
            Hashable
        {
            public let bytes: Int?
            public let lines: Int?
            public let files: Int?

            public init(
                bytes: Int? = nil,
                lines: Int? = nil,
                files: Int? = nil
            ) {
                self.bytes = bytes
                self.lines = lines
                self.files = files
            }

            public static let none = Self()
        }

        public struct Write:
            Sendable,
            Codable,
            Hashable
        {
            public let count: Int
            public let bytes: Int?
            public let changedLines: Int?

            public init(
                count: Int = 0,
                bytes: Int? = nil,
                changedLines: Int? = nil
            ) {
                self.count = count
                self.bytes = bytes
                self.changedLines = changedLines
            }

            public static let none = Self()
        }

        public struct Context:
            Sendable,
            Codable,
            Hashable
        {
            public let bytes: Int?
            public let tokens: Int?
            public let files: Int?
            public let largestSourceTokens: Int?

            public init(
                bytes: Int? = nil,
                tokens: Int? = nil,
                files: Int? = nil,
                largestSourceTokens: Int? = nil
            ) {
                self.bytes = bytes
                self.tokens = tokens
                self.files = files
                self.largestSourceTokens = largestSourceTokens
            }

            public static let none = Self()
        }
    }

    struct Preview:
        Sendable,
        Codable,
        Hashable
    {
        public let command: String?
        public let difference: Difference?

        public init(
            command: String? = nil,
            difference: Difference? = nil
        ) {
            self.command = command
            self.difference = difference
        }

        public static let none = Self()

        public var isEmpty: Bool {
            command == nil
                && (difference?.isEmpty ?? true)
        }

        public struct Difference:
            Sendable,
            Codable,
            Hashable
        {
            public let title: String?
            public let layout: DifferenceLayout

            public init(
                title: String? = nil,
                layout: DifferenceLayout
            ) {
                self.title = title
                self.layout = layout
            }

            public var isEmpty: Bool {
                layout.isEmpty
            }
        }
    }
}

// Deprecated compatibility

@available(
    *,
    deprecated,
    renamed: "ToolPreflight.Preview.Difference"
)
public typealias ToolPreflightDiffPreview =
    ToolPreflight.Preview.Difference

public extension ToolPreflight {
    @available(*, deprecated, message: "Use access.targets.")
    var targetPaths: [String] {
        access.targets
    }

    @available(*, deprecated, message: "Use access.roots.")
    var rootIDs: [String] {
        access.roots
    }

    @available(*, deprecated, message: "Use access.capabilities.")
    var capabilitiesRequired: [WorkspaceCapability] {
        access.capabilities
    }

    @available(*, deprecated, message: "Use access.includesHidden.")
    var includesHiddenPaths: Bool {
        access.includesHidden
    }

    @available(*, deprecated, message: "Use access.followsSymlinks.")
    var followsSymlinks: Bool {
        access.followsSymlinks
    }

    @available(*, deprecated, message: "Use preview.command.")
    var commandPreview: String? {
        preview.command
    }

    @available(*, deprecated, message: "Use preview.difference.")
    var diffPreview: Preview.Difference? {
        preview.difference
    }

    @available(*, deprecated, message: "Use !preview.isEmpty.")
    var isPreview: Bool {
        !preview.isEmpty
    }

    @available(*, deprecated, message: "Use estimates.write.count.")
    var estimatedWriteCount: Int {
        estimates.write.count
    }

    @available(*, deprecated, message: "Use estimates.bytes.")
    var estimatedByteCount: Int? {
        estimates.bytes
    }

    @available(*, deprecated, message: "Use estimates.runtime.")
    var estimatedRuntimeSeconds: TimeInterval? {
        estimates.runtime
    }

    @available(*, deprecated, message: "Use estimates.scan.entries.")
    var estimatedScanEntries: Int? {
        estimates.scan.entries
    }

    @available(*, deprecated, message: "Use estimates.scan.depth.")
    var estimatedScanDepth: Int? {
        estimates.scan.depth
    }

    @available(*, deprecated, message: "Use estimates.read.bytes.")
    var estimatedReadBytes: Int? {
        estimates.read.bytes
    }

    @available(*, deprecated, message: "Use estimates.read.lines.")
    var estimatedReadLines: Int? {
        estimates.read.lines
    }

    @available(*, deprecated, message: "Use estimates.read.files.")
    var estimatedFileReadCount: Int? {
        estimates.read.files
    }

    @available(*, deprecated, message: "Use estimates.write.bytes.")
    var estimatedWriteBytes: Int? {
        estimates.write.bytes
    }

    @available(*, deprecated, message: "Use estimates.write.changedLines.")
    var estimatedChangedLineCount: Int? {
        estimates.write.changedLines
    }

    @available(*, deprecated, message: "Use estimates.outputBytes.")
    var estimatedToolOutputBytes: Int? {
        estimates.outputBytes
    }

    @available(*, deprecated, message: "Use estimates.context.bytes.")
    var estimatedContextBytes: Int? {
        estimates.context.bytes
    }

    @available(*, deprecated, message: "Use estimates.context.tokens.")
    var estimatedContextTokens: Int? {
        estimates.context.tokens
    }

    @available(*, deprecated, message: "Use estimates.context.files.")
    var estimatedContextFiles: Int? {
        estimates.context.files
    }

    @available(*, deprecated, message: "Use estimates.context.largestSourceTokens.")
    var estimatedLargestSourceTokens: Int? {
        estimates.context.largestSourceTokens
    }

    @available(*, deprecated, message: "Use estimates.maximumByteCount.")
    var maximumEstimatedByteCount: Int? {
        estimates.maximumByteCount
    }

    @available(*, deprecated, message: "Use access.hasFilesystemAccess.")
    var hasEstimatedFilesystemAccess: Bool {
        access.hasFilesystemAccess
    }

}

public extension ToolPreflight {
    @available(
        *,
        deprecated,
        message: "Use init(tool:risk:summary:access:estimates:preview:sideEffects:policyChecks:warnings:)."
    )
    init(
        tool: ToolIdentifier,
        risk: ActionRisk,
        targetPaths: [String] = [],
        summary: String,
        commandPreview: String? = nil,
        estimatedWriteCount: Int = 0,
        estimatedByteCount: Int? = nil,
        estimatedRuntimeSeconds: TimeInterval? = nil,
        sideEffects: [String] = [],
        rootIDs: [String] = [],
        capabilitiesRequired: [WorkspaceCapability] = [],
        estimatedScanEntries: Int? = nil,
        estimatedScanDepth: Int? = nil,
        estimatedReadBytes: Int? = nil,
        estimatedReadLines: Int? = nil,
        estimatedFileReadCount: Int? = nil,
        estimatedWriteBytes: Int? = nil,
        estimatedChangedLineCount: Int? = nil,
        estimatedToolOutputBytes: Int? = nil,
        estimatedContextBytes: Int? = nil,
        estimatedContextTokens: Int? = nil,
        estimatedContextFiles: Int? = nil,
        estimatedLargestSourceTokens: Int? = nil,
        includesHiddenPaths: Bool = false,
        followsSymlinks: Bool = false,
        isPreview: Bool = false,
        policyChecks: [String] = [],
        warnings: [String] = [],
        diffPreview: Preview.Difference? = nil
    ) {
        _ = isPreview

        self.init(
            tool: tool,
            risk: risk,
            summary: summary,
            access: .init(
                targets: targetPaths,
                roots: rootIDs,
                capabilities: capabilitiesRequired,
                includesHidden: includesHiddenPaths,
                followsSymlinks: followsSymlinks
            ),
            estimates: .init(
                scan: .init(
                    entries: estimatedScanEntries,
                    depth: estimatedScanDepth
                ),
                read: .init(
                    bytes: estimatedReadBytes,
                    lines: estimatedReadLines,
                    files: estimatedFileReadCount
                ),
                write: .init(
                    count: estimatedWriteCount,
                    bytes: estimatedWriteBytes,
                    changedLines: estimatedChangedLineCount
                ),
                context: .init(
                    bytes: estimatedContextBytes,
                    tokens: estimatedContextTokens,
                    files: estimatedContextFiles,
                    largestSourceTokens: estimatedLargestSourceTokens
                ),
                runtime: estimatedRuntimeSeconds,
                bytes: estimatedByteCount,
                outputBytes: estimatedToolOutputBytes
            ),
            preview: .init(
                command: commandPreview,
                difference: diffPreview
            ),
            sideEffects: sideEffects,
            policyChecks: policyChecks,
            warnings: warnings
        )
    }
}
