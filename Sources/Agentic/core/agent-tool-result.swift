import Primitives

public struct AgentToolResult: Sendable, Codable, Hashable {
    public let toolCallID: String
    public let name: String?
    public let output: JSONValue
    public let processing: AgentToolResultProcessing?
    public let isError: Bool

    public init(
        toolCallID: String,
        name: String? = nil,
        output: JSONValue,
        processing: AgentToolResultProcessing? = nil,
        isError: Bool = false
    ) {
        self.toolCallID = toolCallID
        self.name = name
        self.output = output
        self.processing = processing
        self.isError = isError
    }
}
