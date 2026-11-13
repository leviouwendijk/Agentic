import Foundation

public struct Message: Sendable, Codable, Hashable, Identifiable {
    public let id: String
    public let role: MessageRole
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
