import Position

public struct EditFileToolOutput: Sendable, Codable, Hashable {
    public let path: String
    public let operationCount: Int
    public let changeCount: Int
    public let diffSummary: FileDiffSummary
    public let originalChangedLineRanges: [LineRange]
    public let editedChangedLineRanges: [LineRange]

    public init(
        path: String,
        operationCount: Int,
        changeCount: Int,
        diffSummary: FileDiffSummary,
        originalChangedLineRanges: [LineRange],
        editedChangedLineRanges: [LineRange]
    ) {
        self.path = path
        self.operationCount = operationCount
        self.changeCount = changeCount
        self.diffSummary = diffSummary
        self.originalChangedLineRanges = originalChangedLineRanges
        self.editedChangedLineRanges = editedChangedLineRanges
    }
}
