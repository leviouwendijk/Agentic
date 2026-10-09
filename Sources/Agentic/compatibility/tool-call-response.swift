import Primitives

extension ToolCall.Response {
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

