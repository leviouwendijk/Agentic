public struct ReadFileToolInput: Sendable, Codable, Hashable {
    public let path: String
    public let startLine: Int?
    public let endLine: Int?
    public let maxLines: Int?
    public let includeLineNumbers: Bool

    public init(
        path: String,
        startLine: Int? = nil,
        endLine: Int? = nil,
        maxLines: Int? = nil,
        includeLineNumbers: Bool = false
    ) {
        self.path = path
        self.startLine = startLine
        self.endLine = endLine
        self.maxLines = maxLines
        self.includeLineNumbers = includeLineNumbers
    }
}
