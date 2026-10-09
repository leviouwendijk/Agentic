import Primitives

public extension ToolCall {
    struct Response:
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
}


