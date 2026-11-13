public enum AgentStopReason: String, Sendable, Codable, Hashable, CaseIterable {
    case end_turn
    case tool_use
    case max_tokens
    case stop_sequence
    case error
}
