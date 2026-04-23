import Primitives

public struct AgentToolCall: Sendable, Codable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let input: JSONValue

    public init(
        id: String,
        name: String,
        input: JSONValue
    ) {
        self.id = id
        self.name = name
        self.input = input
    }
}
