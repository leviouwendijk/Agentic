public struct TodoItem: Sendable, Codable, Hashable, Identifiable {
    public let id: TodoIdentifier
    public var text: String
    public var status: TodoStatus

    public init(
        id: TodoIdentifier,
        text: String,
        status: TodoStatus = .pending
    ) {
        self.id = id
        self.text = text
        self.status = status
    }
}
