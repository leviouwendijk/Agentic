public enum AgentModelCapability: String, Sendable, Codable, Hashable, CaseIterable {
    case text
    case tool_use
    case streaming
    case structured_output
    case vision
    case audio_input
    case audio_output
    case reasoning
    case local_execution
}
