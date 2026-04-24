public enum AgentCostProjectionConfidence: String, Sendable, Codable, Hashable, CaseIterable {
    case estimated
    case providerReported
    case unavailable
}
