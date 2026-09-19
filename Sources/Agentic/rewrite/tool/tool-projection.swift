public protocol ToolProjection: Producer {
    func process(
        _ output: Output,
        input: Input
    ) throws -> ToolCall.ResultProjection?
}

public extension ToolProjection {
    func process(
        _ output: Output,
        input: Input
    ) throws -> ToolCall.ResultProjection? {
        nil
    }
}
