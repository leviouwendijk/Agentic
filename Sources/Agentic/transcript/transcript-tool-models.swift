public enum TranscriptEventKind: String, Sendable, Codable, Hashable, CaseIterable {
    case message
    case tool_call
    case tool_result
    case session_branch
    case note
}

public struct TranscriptEventRecord: Sendable, Codable, Hashable {
    public let index: Int
    public let id: String
    public let kind: TranscriptEventKind
    public let summary: String
    public let text: String?
    public let messageRole: AgentRole?
    public let toolName: String?
    public let isError: Bool?

    public init(
        index: Int,
        id: String,
        kind: TranscriptEventKind,
        summary: String,
        text: String?,
        messageRole: AgentRole?,
        toolName: String?,
        isError: Bool?
    ) {
        self.index = index
        self.id = id
        self.kind = kind
        self.summary = summary
        self.text = text
        self.messageRole = messageRole
        self.toolName = toolName
        self.isError = isError
    }
}

public struct TranscriptWindowSummary: Sendable, Codable, Hashable {
    public let totalEventCount: Int
    public let selectedEventCount: Int
    public let firstIndex: Int?
    public let lastIndex: Int?
    public let countsByKind: [String: Int]
    public let countsByRole: [String: Int]
    public let countsByToolName: [String: Int]
    public let approximateCharacterCount: Int
    public let excerpts: [String]
    public let summary: String

    public init(
        totalEventCount: Int,
        selectedEventCount: Int,
        firstIndex: Int?,
        lastIndex: Int?,
        countsByKind: [String: Int],
        countsByRole: [String: Int],
        countsByToolName: [String: Int],
        approximateCharacterCount: Int,
        excerpts: [String],
        summary: String
    ) {
        self.totalEventCount = totalEventCount
        self.selectedEventCount = selectedEventCount
        self.firstIndex = firstIndex
        self.lastIndex = lastIndex
        self.countsByKind = countsByKind
        self.countsByRole = countsByRole
        self.countsByToolName = countsByToolName
        self.approximateCharacterCount = approximateCharacterCount
        self.excerpts = excerpts
        self.summary = summary
    }
}
