import Primitives

public struct AgentToolResult: Sendable, Codable, Hashable {
    public let toolCallID: String
    public let name: String?
    public let output: JSONValue
    public let isError: Bool

    public init(
        toolCallID: String,
        name: String? = nil,
        output: JSONValue,
        isError: Bool = false
    ) {
        self.toolCallID = toolCallID
        self.name = name
        self.output = output
        self.isError = isError
    }
}
