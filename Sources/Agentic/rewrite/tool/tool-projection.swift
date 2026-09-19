public protocol ToolProjection: ToolContract {
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
