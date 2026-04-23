import Concatenation

public struct ContextFileSource: Sendable, Codable, Hashable {
    public var includes: [String]
    public var excludes: [String]
    public var selections: [String]
    public var recursive: Bool
    public var includeHidden: Bool
    public var followSymlinks: Bool
    public var delimiterStyle: DelimiterStyle
    public var includeSourceLineNumbers: Bool
    public var maxLinesPerFile: Int?

    public init(
        includes: [String] = [],
        excludes: [String] = [],
        selections: [String] = [],
        recursive: Bool = true,
        includeHidden: Bool = false,
        followSymlinks: Bool = false,
        delimiterStyle: DelimiterStyle = .boxed,
        includeSourceLineNumbers: Bool = false,
        maxLinesPerFile: Int? = 10_000
    ) {
        self.includes = includes
        self.excludes = excludes
        self.selections = selections
        self.recursive = recursive
        self.includeHidden = includeHidden
        self.followSymlinks = followSymlinks
        self.delimiterStyle = delimiterStyle
        self.includeSourceLineNumbers = includeSourceLineNumbers
        self.maxLinesPerFile = maxLinesPerFile
    }
}
