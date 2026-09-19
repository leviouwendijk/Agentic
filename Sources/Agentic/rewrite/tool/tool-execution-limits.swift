import Foundation

public struct ExecutionLimits:
    Sendable,
    Codable,
    Hashable
{
    public var paths: Paths
    public var reads: Reads
    public var writes: Writes
    public var context: Context
    public var runtime: Runtime

    public init(
        paths: Paths = .unlimited,
        reads: Reads = .unlimited,
        writes: Writes = .unlimited,
        context: Context = .unlimited,
        runtime: Runtime = .unlimited
    ) {
        self.paths = paths
        self.reads = reads
        self.writes = writes
        self.context = context
        self.runtime = runtime
    }

    public static let unlimited = Self()
}

public extension ExecutionLimits {
    struct Paths:
        Sendable,
        Codable,
        Hashable
    {
        public var targetCount: Int?
        public var scanEntries: Int?
        public var scanDepth: Int?
        public var allowsHidden: Bool?
        public var allowsSymlinks: Bool?
        public var rootCount: Int?

        public init(
            targetCount: Int? = nil,
            scanEntries: Int? = nil,
            scanDepth: Int? = nil,
            allowsHidden: Bool? = nil,
            allowsSymlinks: Bool? = nil,
            rootCount: Int? = nil
        ) {
            self.targetCount = targetCount
            self.scanEntries = scanEntries
            self.scanDepth = scanDepth
            self.allowsHidden = allowsHidden
            self.allowsSymlinks = allowsSymlinks
            self.rootCount = rootCount
        }

        public static let unlimited = Self()

        public var isUnlimited: Bool {
            targetCount == nil
                && scanEntries == nil
                && scanDepth == nil
                && allowsHidden == nil
                && allowsSymlinks == nil
                && rootCount == nil
        }

        public func merged(
            with override: Self
        ) -> Self {
            .init(
                targetCount: override.targetCount ?? targetCount,
                scanEntries: override.scanEntries ?? scanEntries,
                scanDepth: override.scanDepth ?? scanDepth,
                allowsHidden: override.allowsHidden ?? allowsHidden,
                allowsSymlinks: override.allowsSymlinks ?? allowsSymlinks,
                rootCount: override.rootCount ?? rootCount
            )
        }
    }

    struct Reads:
        Sendable,
        Codable,
        Hashable
    {
        public var bytes: Int?
        public var lines: Int?
        public var files: Int?
        public var outputBytes: Int?

        public init(
            bytes: Int? = nil,
            lines: Int? = nil,
            files: Int? = nil,
            outputBytes: Int? = nil
        ) {
            self.bytes = bytes
            self.lines = lines
            self.files = files
            self.outputBytes = outputBytes
        }

        public static let unlimited = Self()

        public var isUnlimited: Bool {
            bytes == nil
                && lines == nil
                && files == nil
                && outputBytes == nil
        }

        public func merged(
            with override: Self
        ) -> Self {
            .init(
                bytes: override.bytes ?? bytes,
                lines: override.lines ?? lines,
                files: override.files ?? files,
                outputBytes: override.outputBytes ?? outputBytes
            )
        }
    }

    struct Writes:
        Sendable,
        Codable,
        Hashable
    {
        public var bytes: Int?
        public var count: Int?
        public var changedLines: Int?
        public var requirePreview: Bool?

        public init(
            bytes: Int? = nil,
            count: Int? = nil,
            changedLines: Int? = nil,
            requirePreview: Bool? = nil
        ) {
            self.bytes = bytes
            self.count = count
            self.changedLines = changedLines
            self.requirePreview = requirePreview
        }

        public static let unlimited = Self()

        public var isUnlimited: Bool {
            bytes == nil
                && count == nil
                && changedLines == nil
                && requirePreview == nil
        }

        public func merged(
            with override: Self
        ) -> Self {
            .init(
                bytes: override.bytes ?? bytes,
                count: override.count ?? count,
                changedLines: override.changedLines ?? changedLines,
                requirePreview: override.requirePreview ?? requirePreview
            )
        }
    }

    struct Context:
        Sendable,
        Codable,
        Hashable
    {
        public var bytes: Int?
        public var tokens: Int?
        public var files: Int?
        public var linesPerFile: Int?
        public var largestSourceTokens: Int?

        public init(
            bytes: Int? = nil,
            tokens: Int? = nil,
            files: Int? = nil,
            linesPerFile: Int? = nil,
            largestSourceTokens: Int? = nil
        ) {
            self.bytes = bytes
            self.tokens = tokens
            self.files = files
            self.linesPerFile = linesPerFile
            self.largestSourceTokens = largestSourceTokens
        }

        public static let unlimited = Self()

        public var isUnlimited: Bool {
            bytes == nil
                && tokens == nil
                && files == nil
                && linesPerFile == nil
                && largestSourceTokens == nil
        }

        public func merged(
            with override: Self
        ) -> Self {
            .init(
                bytes: override.bytes ?? bytes,
                tokens: override.tokens ?? tokens,
                files: override.files ?? files,
                linesPerFile: override.linesPerFile ?? linesPerFile,
                largestSourceTokens: override.largestSourceTokens ?? largestSourceTokens
            )
        }
    }

    struct Runtime:
        Sendable,
        Codable,
        Hashable
    {
        public var seconds: TimeInterval?
        public var iterations: Int?

        public init(
            seconds: TimeInterval? = nil,
            iterations: Int? = nil
        ) {
            self.seconds = seconds
            self.iterations = iterations
        }

        public static let unlimited = Self()

        public var isUnlimited: Bool {
            seconds == nil
                && iterations == nil
        }

        public func merged(
            with override: Self
        ) -> Self {
            .init(
                seconds: override.seconds ?? seconds,
                iterations: override.iterations ?? iterations
            )
        }
    }
}

public extension ExecutionLimits {
    var isUnlimited: Bool {
        paths.isUnlimited
            && reads.isUnlimited
            && writes.isUnlimited
            && context.isUnlimited
            && runtime.isUnlimited
    }

    func merged(
        with override: ExecutionLimits?
    ) -> ExecutionLimits {
        guard let override else {
            return self
        }

        return .init(
            paths: paths.merged(
                with: override.paths
            ),
            reads: reads.merged(
                with: override.reads
            ),
            writes: writes.merged(
                with: override.writes
            ),
            context: context.merged(
                with: override.context
            ),
            runtime: runtime.merged(
                with: override.runtime
            )
        )
    }

    func requiresHumanReview(
        for preflight: ToolPreflight
    ) -> Bool {
        pathRequiresHumanReview(
            for: preflight
        ) || readRequiresHumanReview(
            for: preflight
        ) || writeRequiresHumanReview(
            for: preflight
        ) || contextRequiresHumanReview(
            for: preflight
        ) || runtimeRequiresHumanReview(
            for: preflight
        )
    }
}

private extension ExecutionLimits {
    func pathRequiresHumanReview(
        for preflight: ToolPreflight
    ) -> Bool {
        if let targetCount = paths.targetCount,
           preflight.access.targets.count > targetCount {
            return true
        }

        if let scanEntries = paths.scanEntries,
           let estimated = preflight.estimates.scan.entries,
           estimated > scanEntries {
            return true
        }

        if let scanDepth = paths.scanDepth,
           let estimated = preflight.estimates.scan.depth,
           estimated > scanDepth {
            return true
        }

        if paths.allowsHidden == false,
           preflight.access.includesHidden {
            return true
        }

        if paths.allowsSymlinks == false,
           preflight.access.followsSymlinks {
            return true
        }

        if let rootCount = paths.rootCount,
           preflight.access.roots.count > rootCount {
            return true
        }

        return false
    }

    func readRequiresHumanReview(
        for preflight: ToolPreflight
    ) -> Bool {
        if let bytes = reads.bytes,
           let estimated = preflight.estimates.read.bytes,
           estimated > bytes {
            return true
        }

        if let lines = reads.lines,
           let estimated = preflight.estimates.read.lines,
           estimated > lines {
            return true
        }

        if let files = reads.files,
           let estimated = preflight.estimates.read.files,
           estimated > files {
            return true
        }

        if let outputBytes = reads.outputBytes,
           let estimated = preflight.estimates.outputBytes,
           estimated > outputBytes {
            return true
        }

        return false
    }

    func writeRequiresHumanReview(
        for preflight: ToolPreflight
    ) -> Bool {
        if let count = writes.count,
           preflight.estimates.write.count > count {
            return true
        }

        if let bytes = writes.bytes,
           let estimated = preflight.estimates.write.bytes,
           estimated > bytes {
            return true
        }

        if let changedLines = writes.changedLines,
           let estimated = preflight.estimates.write.changedLines,
           estimated > changedLines {
            return true
        }

        if writes.requirePreview == true,
           preflight.estimates.write.count > 0,
           preflight.preview.isEmpty {
            return true
        }

        return false
    }

    func contextRequiresHumanReview(
        for preflight: ToolPreflight
    ) -> Bool {
        if let bytes = context.bytes,
           let estimated = preflight.estimates.context.bytes,
           estimated > bytes {
            return true
        }

        if let tokens = context.tokens,
           let estimated = preflight.estimates.context.tokens,
           estimated > tokens {
            return true
        }

        if let files = context.files,
           let estimated = preflight.estimates.context.files,
           estimated > files {
            return true
        }

        if let linesPerFile = context.linesPerFile,
           let estimated = preflight.estimates.read.lines,
           estimated > linesPerFile {
            return true
        }

        if let largestSourceTokens = context.largestSourceTokens,
           let estimated = preflight.estimates.context.largestSourceTokens,
           estimated > largestSourceTokens {
            return true
        }

        return false
    }

    func runtimeRequiresHumanReview(
        for preflight: ToolPreflight
    ) -> Bool {
        if let seconds = runtime.seconds,
           let estimated = preflight.estimates.runtime,
           estimated > seconds {
            return true
        }

        return false
    }
}

// Deprecated compatibility

@available(
    *,
    deprecated,
    renamed: "ExecutionLimits.Paths"
)
public typealias PathExecutionLimits =
    ExecutionLimits.Paths

@available(
    *,
    deprecated,
    renamed: "ExecutionLimits.Reads"
)
public typealias ReadExecutionLimits =
    ExecutionLimits.Reads

@available(
    *,
    deprecated,
    renamed: "ExecutionLimits.Writes"
)
public typealias WriteExecutionLimits =
    ExecutionLimits.Writes

@available(
    *,
    deprecated,
    renamed: "ExecutionLimits.Context"
)
public typealias ContextExecutionLimits =
    ExecutionLimits.Context

@available(
    *,
    deprecated,
    renamed: "ExecutionLimits.Runtime"
)
public typealias RuntimeExecutionLimits =
    ExecutionLimits.Runtime

public extension ExecutionLimits.Paths {
    @available(*, deprecated, message: "Use targetCount.")
    var maxTargetPathCount: Int? {
        get {
            targetCount
        }
        set {
            targetCount = newValue
        }
    }

    @available(*, deprecated, message: "Use scanEntries.")
    var maxScanEntries: Int? {
        get {
            scanEntries
        }
        set {
            scanEntries = newValue
        }
    }

    @available(*, deprecated, message: "Use scanDepth.")
    var maxScanDepth: Int? {
        get {
            scanDepth
        }
        set {
            scanDepth = newValue
        }
    }

    @available(*, deprecated, message: "Use allowsHidden.")
    var allowHidden: Bool? {
        get {
            allowsHidden
        }
        set {
            allowsHidden = newValue
        }
    }

    @available(*, deprecated, message: "Use allowsSymlinks.")
    var allowSymlinks: Bool? {
        get {
            allowsSymlinks
        }
        set {
            allowsSymlinks = newValue
        }
    }

    @available(*, deprecated, message: "Use rootCount.")
    var maxRootsPerToolCall: Int? {
        get {
            rootCount
        }
        set {
            rootCount = newValue
        }
    }

}

public extension ExecutionLimits.Paths {
    @available(
        *,
        deprecated,
        message: "Use init(targetCount:scanEntries:scanDepth:allowsHidden:allowsSymlinks:rootCount:)."
    )
    init(
        maxTargetPathCount: Int?,
        maxScanEntries: Int? = nil,
        maxScanDepth: Int? = nil,
        allowHidden: Bool? = nil,
        allowSymlinks: Bool? = nil,
        maxRootsPerToolCall: Int? = nil
    ) {
        self.init(
            targetCount: maxTargetPathCount,
            scanEntries: maxScanEntries,
            scanDepth: maxScanDepth,
            allowsHidden: allowHidden,
            allowsSymlinks: allowSymlinks,
            rootCount: maxRootsPerToolCall
        )
    }
}

public extension ExecutionLimits.Reads {
    @available(*, deprecated, message: "Use bytes.")
    var maxReadBytes: Int? {
        get {
            bytes
        }
        set {
            bytes = newValue
        }
    }

    @available(*, deprecated, message: "Use lines.")
    var maxReadLines: Int? {
        get {
            lines
        }
        set {
            lines = newValue
        }
    }

    @available(*, deprecated, message: "Use files.")
    var maxFilesPerRead: Int? {
        get {
            files
        }
        set {
            files = newValue
        }
    }

    @available(*, deprecated, message: "Use outputBytes.")
    var maxToolOutputBytes: Int? {
        get {
            outputBytes
        }
        set {
            outputBytes = newValue
        }
    }

}

public extension ExecutionLimits.Reads {
    @available(
        *,
        deprecated,
        message: "Use init(bytes:lines:files:outputBytes:)."
    )
    init(
        maxReadBytes: Int?,
        maxReadLines: Int? = nil,
        maxFilesPerRead: Int? = nil,
        maxToolOutputBytes: Int? = nil
    ) {
        self.init(
            bytes: maxReadBytes,
            lines: maxReadLines,
            files: maxFilesPerRead,
            outputBytes: maxToolOutputBytes
        )
    }
}

public extension ExecutionLimits.Writes {
    @available(*, deprecated, message: "Use bytes.")
    var maxWriteBytes: Int? {
        get {
            bytes
        }
        set {
            bytes = newValue
        }
    }

    @available(*, deprecated, message: "Use count.")
    var maxWriteCount: Int? {
        get {
            count
        }
        set {
            count = newValue
        }
    }

    @available(*, deprecated, message: "Use changedLines.")
    var maxChangedLineCount: Int? {
        get {
            changedLines
        }
        set {
            changedLines = newValue
        }
    }

    @available(*, deprecated, message: "Use requirePreview.")
    var requirePreviewForWrites: Bool? {
        get {
            requirePreview
        }
        set {
            requirePreview = newValue
        }
    }

}

public extension ExecutionLimits.Writes {
    @available(
        *,
        deprecated,
        message: "Use init(bytes:count:changedLines:requirePreview:)."
    )
    init(
        maxWriteBytes: Int?,
        maxWriteCount: Int? = nil,
        maxChangedLineCount: Int? = nil,
        requirePreviewForWrites: Bool? = nil
    ) {
        self.init(
            bytes: maxWriteBytes,
            count: maxWriteCount,
            changedLines: maxChangedLineCount,
            requirePreview: requirePreviewForWrites
        )
    }
}

public extension ExecutionLimits.Context {
    @available(*, deprecated, message: "Use bytes.")
    var maxContextBytes: Int? {
        get {
            bytes
        }
        set {
            bytes = newValue
        }
    }

    @available(*, deprecated, message: "Use tokens.")
    var maxContextTokens: Int? {
        get {
            tokens
        }
        set {
            tokens = newValue
        }
    }

    @available(*, deprecated, message: "Use files.")
    var maxFiles: Int? {
        get {
            files
        }
        set {
            files = newValue
        }
    }

    @available(*, deprecated, message: "Use linesPerFile.")
    var maxLinesPerFile: Int? {
        get {
            linesPerFile
        }
        set {
            linesPerFile = newValue
        }
    }

    @available(*, deprecated, message: "Use largestSourceTokens.")
    var maxLargestSourceTokens: Int? {
        get {
            largestSourceTokens
        }
        set {
            largestSourceTokens = newValue
        }
    }

}

public extension ExecutionLimits.Context {
    @available(
        *,
        deprecated,
        message: "Use init(bytes:tokens:files:linesPerFile:largestSourceTokens:)."
    )
    init(
        maxContextBytes: Int?,
        maxContextTokens: Int? = nil,
        maxFiles: Int? = nil,
        maxLinesPerFile: Int? = nil,
        maxLargestSourceTokens: Int? = nil
    ) {
        self.init(
            bytes: maxContextBytes,
            tokens: maxContextTokens,
            files: maxFiles,
            linesPerFile: maxLinesPerFile,
            largestSourceTokens: maxLargestSourceTokens
        )
    }
}

public extension ExecutionLimits.Runtime {
    @available(*, deprecated, message: "Use seconds.")
    var maxRuntimeSeconds: TimeInterval? {
        get {
            seconds
        }
        set {
            seconds = newValue
        }
    }

    @available(*, deprecated, message: "Use iterations.")
    var maxIterations: Int? {
        get {
            iterations
        }
        set {
            iterations = newValue
        }
    }

}

public extension ExecutionLimits.Runtime {
    @available(
        *,
        deprecated,
        message: "Use init(seconds:iterations:)."
    )
    init(
        maxRuntimeSeconds: TimeInterval?,
        maxIterations: Int? = nil
    ) {
        self.init(
            seconds: maxRuntimeSeconds,
            iterations: maxIterations
        )
    }
}
