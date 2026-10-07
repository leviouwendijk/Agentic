import Primitives

public struct ToolResult:
    Sendable,
    Codable,
    Hashable
{
    public let call: ToolCall.Reference
    public let output: JSONValue
    public let projection: ToolCall.ResultProjection?
    public let isError: Bool

    public init(
        call: ToolCall.Reference,
        output: JSONValue,
        projection: ToolCall.ResultProjection? = nil,
        isError: Bool = false
    ) {
        self.call = call
        self.output = output
        self.projection = projection
        self.isError = isError
    }
}

extension ToolResult {
    @available(
        *,
        deprecated,
        message: "Use init(call:output:projection:isError:) with ToolCall.Reference."
    )
    public init(
        toolCallID: String,
        tool: ToolIdentifier,
        output: JSONValue,
        projection: ToolCall.ResultProjection? = nil,
        isError: Bool = false
    ) {
        self.init(
            call: .init(
                id: toolCallID,
                tool: tool
            ),
            output: output,
            projection: projection,
            isError: isError
        )
    }

    @available(
        *,
        deprecated,
        message: "Use call.id instead."
    )
    public var toolCallID: String {
        call.id
    }

    @available(
        *,
        deprecated,
        message: "Use call.tool instead."
    )
    public var tool: ToolIdentifier {
        call.tool
    }
}
