public protocol ToolProjection: Producer {
    func process(
        _ output: Output,
        input: Input
    ) throws -> ToolExecution.Projection?
}

public extension ToolProjection {
    func process(
        _ output: Output,
        input: Input
    ) throws -> ToolExecution.Projection? {
        nil
    }
}
