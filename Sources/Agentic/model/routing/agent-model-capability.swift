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
    /// The gateway passes a call to a tool outside the request's
    /// definitions back to the run, so a capability known only from its
    /// contract in the history can be called by its own name. Without it
    /// (calls are dropped) such capabilities go through `standard_tool_call_capability`.
    case undeclared_calls
}
