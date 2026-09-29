import Primitives

public struct ToolResult:
    Sendable,
    Codable,
    Hashable
{
    public let toolCallID: String
    public let tool: ToolIdentifier?
    public let output: JSONValue
    public let projection: ToolCall.ResultProjection?
    public let isError: Bool

    public init(
        toolCallID: String,
        tool: ToolIdentifier? = nil,
        output: JSONValue,
        projection: ToolCall.ResultProjection? = nil,
        isError: Bool = false
    ) {
        self.toolCallID = toolCallID
        self.tool = tool
        self.output = output
        self.projection = projection
        self.isError = isError
    }
}
