/// The text the model reads for a Tool's output. The output itself stays
/// the record (log, checkpoints, typed decoding); the rendering only
/// changes what enters the model's context. Default: none, so the model
/// reads the output as JSON.
public protocol ToolRendering: Producer {
    func render(
        _ output: Output,
        input: Input
    ) -> String?
}

public extension ToolRendering {
    func render(
        _ output: Output,
        input: Input
    ) -> String? {
        nil
    }
}
