import Foundation

public struct AgentMessage: Sendable, Codable, Hashable, Identifiable {
    public let id: String
    public let role: AgentRole
    public var content: AgentContent

    public init(
        id: String,
        role: AgentRole,
        content: AgentContent
    ) {
        self.id = id
        self.role = role
        self.content = content
    }
}

public extension AgentMessage {
    init(
        role: AgentRole,
        content: AgentContent
    ) {
        self.init(
            id: UUID().uuidString,
            role: role,
            content: content
        )
    }

    init(
        role: AgentRole,
        text: String
    ) {
        self.init(
            role: role,
            content: .init(text: text)
        )
    }
}
