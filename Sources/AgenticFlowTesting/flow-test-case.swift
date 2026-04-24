enum FlowTestCase: String, Sendable, CaseIterable {
    case buffered
    case stream
    case stream_error = "stream-error"
    case stream_cancel = "stream-cancel"
    case stream_tool_use = "stream-tool-use"
}
