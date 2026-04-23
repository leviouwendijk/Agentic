import Position

public struct ReadFileToolOutput: Sendable, Codable, Hashable {
    public let path: String
    public let content: String
    public let lineRange: LineRange?
    public let lineCount: Int
    public let totalLineCount: Int
    public let byteCount: Int
    public let truncated: Bool
    public let encoding: String?

    public init(
        path: String,
        content: String,
        lineRange: LineRange?,
        lineCount: Int,
        totalLineCount: Int,
        byteCount: Int,
        truncated: Bool,
        encoding: String?
    ) {
        self.path = path
        self.content = content
        self.lineRange = lineRange
        self.lineCount = lineCount
        self.totalLineCount = totalLineCount
        self.byteCount = byteCount
        self.truncated = truncated
        self.encoding = encoding
    }
}
