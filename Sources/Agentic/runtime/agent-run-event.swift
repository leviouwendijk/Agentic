import Foundation

public struct AgentRunEvent: Sendable, Codable, Hashable, Identifiable {
    public enum Kind: String, Sendable, Codable, Hashable, CaseIterable {
        case assistant_response 
        case compaction
        case tool_preflight 
        case tool_approved 
        case tool_denied 
        case pending_approval 
        case tool_result 
        case tool_error 
    }

    public let id: String
    public let kind: Kind
    public let iteration: Int
    public let messageID: String?
    public let toolCallID: String?
    public let toolName: String?
    public let summary: String

    public init(
        id: String = UUID().uuidString,
        kind: Kind,
        iteration: Int,
        messageID: String? = nil,
        toolCallID: String? = nil,
        toolName: String? = nil,
        summary: String
    ) {
        self.id = id
        self.kind = kind
        self.iteration = iteration
        self.messageID = messageID
        self.toolCallID = toolCallID
        self.toolName = toolName
        self.summary = summary
    }
}
