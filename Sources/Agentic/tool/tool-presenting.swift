import Reporting

/// What the user sees for a Tool's output, beside the model-facing
/// `ToolRendering`. The output stays the record; the presentation is a
/// renderer-neutral document the host shows and exports. It never enters
/// the model's context. Default: none.
public protocol ToolPresenting: Producer {
    func present(
        _ output: Output,
        input: Input
    ) -> ToolPresentation?
}

public extension ToolPresenting {
    func present(
        _ output: Output,
        input: Input
    ) -> ToolPresentation? {
        nil
    }
}

/// A Tool's user-facing document and where the host shows it.
public struct ToolPresentation: Sendable, Codable, Hashable {
    public enum Placement: String, Sendable, Codable, Hashable {
        /// In the conversation, under the answer: a result the user asked for.
        case attachment
        /// Only with the call's details: an intermediate result.
        case inspector
    }

    public let document: ReportDocument
    public let placement: Placement

    public init(
        _ document: ReportDocument,
        placement: Placement = .attachment
    ) {
        self.document = document
        self.placement = placement
    }
}
