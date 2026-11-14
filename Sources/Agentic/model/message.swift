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
    /// Opaque, provider-specific replay data. Never rewrite it as model text.
    /// The optional field preserves decoding of persisted older messages.
    public var providerContinuation: [String: String]?

    public init(
        id: String,
        role: MessageRole,
        content: MessageContent,
        providerContinuation: [String: String]? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.providerContinuation = providerContinuation
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
