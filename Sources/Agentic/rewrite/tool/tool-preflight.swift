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

