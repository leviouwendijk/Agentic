public enum AgentModelResponseDelivery: String, Sendable, Codable, Hashable, CaseIterable {
    case buffered
    case stream
}
