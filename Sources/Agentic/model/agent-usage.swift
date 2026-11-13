/// Provider-reported usage, normalized by each gateway to one meaning:
/// - `inputTokens`: input billed at the base rate, excluding cache reads/writes.
/// - `cachedInputReadTokens` / `cachedInputWriteTokens`: input served from / written to a prompt cache.
/// - `outputTokens`: all generated tokens, including reasoning.
/// - `reasoningOutputTokens`: informational subset of `outputTokens`.
/// `nil` means the provider did not report a value, not zero.
public struct AgentUsage: Sendable, Codable, Hashable {
    public var inputTokens: Int?
    public var outputTokens: Int?
    public var totalTokens: Int?
    public var cachedInputReadTokens: Int?
    public var cachedInputWriteTokens: Int?
    public var reasoningOutputTokens: Int?

    public init(
        inputTokens: Int? = nil,
        outputTokens: Int? = nil,
        totalTokens: Int? = nil,
        cachedInputReadTokens: Int? = nil,
        cachedInputWriteTokens: Int? = nil,
        reasoningOutputTokens: Int? = nil
    ) {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.totalTokens = totalTokens
        self.cachedInputReadTokens = cachedInputReadTokens
        self.cachedInputWriteTokens = cachedInputWriteTokens
        self.reasoningOutputTokens = reasoningOutputTokens
    }

    /// Everything the model read for this request: the context size actually sent.
    public var contextTokens: Int? {
        let parts = [
            inputTokens,
            cachedInputReadTokens,
            cachedInputWriteTokens,
        ].compactMap { $0 }

        return parts.isEmpty ? nil : parts.reduce(0, +)
    }
}

public extension AgentUsage {
    var costUsage: AgentCostUsage {
        .init(
            providerUsage: self
        )
    }
}
