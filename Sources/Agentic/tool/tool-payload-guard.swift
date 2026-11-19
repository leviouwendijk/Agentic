import Primitives

/// Keeps sensitive values out of what models read and sessions record
/// while tools still work with them. A host inserts one into `ToolServices`
/// as `ToolPayloadGuarding`; every tool call then passes it twice:
///
/// - inbound, before preflight and the call, handles in the arguments are
///   replaced by their values (or refused);
/// - outbound, the result, its rendering and projection, and the preflight
///   review get handles for sensitive values.
///
/// Reviews, journals, recordings and the model all see the guarded form;
/// only the tool's own call sees values.
public protocol ToolPayloadGuard: Sendable {
    /// `arguments` with handles replaced by values `tool` may use; throws
    /// when it may not use one.
    func resolving(_ arguments: JSONValue, for tool: ToolIdentifier) async throws -> JSONValue

    /// `value`, as it leaves `tool`, with sensitive data replaced.
    func protecting(_ value: JSONValue, from tool: ToolIdentifier) async -> JSONValue

    /// `text`, as it leaves `tool`, with sensitive data replaced.
    func protecting(_ text: String, from tool: ToolIdentifier) async -> String
}

/// The `ToolServices` entry holding the session's guard.
public struct ToolPayloadGuarding: Sendable {
    public let shield: any ToolPayloadGuard

    public init(_ shield: any ToolPayloadGuard) {
        self.shield = shield
    }
}

public extension ToolContext {
    /// The session's payload guard, if the host installed one.
    var payloadGuard: (any ToolPayloadGuard)? {
        (try? require(ToolPayloadGuarding.self))?.shield
    }
}

extension ToolPayloadGuard {
    /// `value` protected through its JSON form; nil when the protected form
    /// no longer decodes (a typed field took a handle), so nothing leaves
    /// unprotected.
    func protectingEncoded<Value: Codable>(_ value: Value, from tool: ToolIdentifier) async -> Value? {
        guard let encoded = try? JSONValue.encoding(value) else { return nil }
        let protected = await protecting(encoded, from: tool)
        return try? protected.decode(Value.self)
    }

    /// `review` protected. Text is always protected; access, estimates and
    /// preview are kept only when their protected form still decodes and
    /// are otherwise withheld with a warning, so no unprotected review
    /// reaches an approval or a journal.
    func protectingReview(_ review: ToolPreflight, from tool: ToolIdentifier) async -> ToolPreflight {
        if let whole = await protectingEncoded(review, from: tool) {
            return whole
        }
        var withheld: [String] = []
        let access = await protectingEncoded(review.access, from: tool)
        if access == nil { withheld.append("access") }
        let estimates = await protectingEncoded(review.estimates, from: tool)
        if estimates == nil { withheld.append("estimates") }
        let preview = await protectingEncoded(review.preview, from: tool)
        if preview == nil { withheld.append("preview") }

        var warnings: [String] = []
        for warning in review.warnings {
            warnings.append(await protecting(warning, from: tool))
        }
        if !withheld.isEmpty {
            warnings.append(
                "Part of this review (\(withheld.joined(separator: ", "))) held a sensitive value in a typed field and is withheld."
            )
        }
        var sideEffects: [String] = []
        for effect in review.sideEffects {
            sideEffects.append(await protecting(effect, from: tool))
        }
        var policyChecks: [String] = []
        for check in review.policyChecks {
            policyChecks.append(await protecting(check, from: tool))
        }
        return ToolPreflight(
            tool: review.tool,
            risk: review.risk,
            summary: await protecting(review.summary, from: tool),
            access: access ?? .none,
            estimates: estimates ?? .none,
            preview: preview ?? .none,
            mayChangeSource: review.mayChangeSource,
            sideEffects: sideEffects,
            policyChecks: policyChecks,
            warnings: warnings
        )
    }

    func resolvingCall(_ call: ToolInvocation) async throws -> ToolInvocation {
        ToolInvocation(
            id: call.id,
            tool: call.tool,
            arguments: try await resolving(call.arguments, for: call.tool),
            execution: call.execution
        )
    }

    func protectingResult(_ result: ToolExecution.Result, from tool: ToolIdentifier) async -> ToolExecution.Result {
        var protected = result
        let response = result.result
        protected.result = FunctionCall.Response(
            call: response.call,
            output: await protecting(response.output, from: tool),
            projection: await response.projection.asyncFlatMap { await protectingEncoded($0, from: tool) },
            isError: response.isError,
            text: await response.text.asyncMap { await protecting($0, from: tool) }
        )
        protected.presentation = await result.presentation.asyncFlatMap { await protectingEncoded($0, from: tool) }
        return protected
    }
}

private extension Optional where Wrapped: Sendable {
    func asyncMap<T>(_ transform: (Wrapped) async -> T) async -> T? {
        guard let self else { return nil }
        return await transform(self)
    }

    func asyncFlatMap<T>(_ transform: (Wrapped) async -> T?) async -> T? {
        guard let self else { return nil }
        return await transform(self)
    }
}
