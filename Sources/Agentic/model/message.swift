import Macros
import Schema
import Foundation

/// One message in a conversation.
@JSONSchema
public struct Message: Sendable, Codable, Hashable, Identifiable {
    /// Stable message identifier.
    public let id: String
    /// Who authored the message.
    public let role: MessageRole
    /// The message's ordered content blocks.
    public var content: MessageContent

    public init(
        id: String,
        role: MessageRole,
        content: MessageContent
    ) {
        self.id = id
        self.role = role
        self.content = content
    }
}

public extension Message {
    init(
        role: MessageRole,
        content: MessageContent
    ) {
        self.init(
            id: UUID().uuidString,
            role: role,
            content: content
        )
    }

    init(
        role: MessageRole,
        text: String
    ) {
        self.init(
            role: role,
            content: .init(text: text)
        )
    }
}
