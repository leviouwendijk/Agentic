import Reporting

/// What the user sees for a Tool's output, beside the model-facing
/// `ToolRendering`. The output stays the record; the presentation is a
/// renderer-neutral document the host shows as an attachment and exports.
/// It never enters the model's context. Default: none.
public protocol ToolPresenting: Producer {
    func present(
        _ output: Output,
        input: Input
    ) -> ReportDocument?
}

public extension ToolPresenting {
    func present(
        _ output: Output,
        input: Input
    ) -> ReportDocument? {
        nil
    }
}
