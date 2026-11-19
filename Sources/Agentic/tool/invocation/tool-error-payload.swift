import Errors
import Foundation
import Primitives

/// What a model reads when a call fails. `message` is always there; `error`
/// carries the rest of a structured error (its code, reason, suggestion,
/// disposition, context, fields and causes) and is left out when the error
/// has nothing beyond its message.
///
/// Built by `FunctionCall.Response.toolError`, which redacts secrets and
/// passes the payload through the session's guard like any tool result.
public struct ToolErrorPayload:
    Codable,
    Sendable,
    Hashable
{
    public let kind: String
    public let callID: String
    public let toolName: String
    /// The phase a wrapped tool failure happened in (`decode`, `call`, …).
    public let phase: String?
    public let message: String
    /// How to make the next call right, when the host knows.
    public let guidance: String?
    public let error: ErrorSummary?

    public init(
        call: FunctionCall.Reference,
        error: any Swift.Error,
        guidance: String? = nil
    ) {
        let execution =
            error.withoutContext as? ToolExecution.Error
        // The wrapper names the tool and call, which the payload already
        // does; the model needs what the tool itself raised.
        let subject: any Swift.Error =
            execution?.underlying
            ?? error

        let summary =
            subject.summary(
                capture: .model,
                redaction: .internal_diagnostic
            )

        self.kind = "tool_error"
        self.callID = call.id
        self.toolName = call.name
        self.phase = execution?.failure.phase.rawValue
        self.guidance = guidance

        if summary == ErrorSummary(message: summary.message) {
            self.message =
                Self.plainMessage(
                    for: subject,
                    summary: summary
                )
            self.error = nil
        } else {
            self.message = summary.message
            self.error = summary
        }
    }

    /// A plain error's own description: a Swift error without a
    /// `LocalizedError` text says more about itself (`invalidPath("x")`)
    /// than Foundation's generic sentence.
    private static func plainMessage(
        for error: any Swift.Error,
        summary: ErrorSummary
    ) -> String {
        if let localized = error as? any LocalizedError,
           let description = localized.errorDescription,
           !description.isEmpty
        {
            return description
        }

        if type(of: error) is NSError.Type
            || error is any CustomNSError
        {
            return summary.message
        }

        return String(describing: error)
    }
}

public extension FunctionCall.Response {
    /// A failed call's result: the error as a `ToolErrorPayload`, protected
    /// by `guard` (the session's payload guard) before anything records or
    /// sends it.
    static func toolError(
        call: FunctionCall.Reference,
        error: any Swift.Error,
        guidance: String? = nil,
        guard shield: (any ToolPayloadGuard)?
    ) async throws -> Self {
        let output = try JSONValue.encoding(
            ToolErrorPayload(
                call: call,
                error: error,
                guidance: guidance
            )
        )

        return FunctionCall.Response(
            call: call,
            output:
                await shield?.protecting(
                    output,
                    from: ToolIdentifier(call.name)
                )
                ?? output,
            isError: true
        )
    }
}
