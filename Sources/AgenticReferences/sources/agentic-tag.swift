import References

public enum AgenticTag: String, Sendable, Codable, Hashable, CaseIterable, ReferenceTagRepresentable {
    public static let namespace = "agentic"

    case harness
    case harness_optimization
    case meta_agents
    case execution_traces
    case replay_and_forking
    case runtime_intervention

    case context_management
    case context_compression
    case trajectory_reduction
    case prompt_caching

    case cost_efficiency
    case latency
    case model_routing
    case model_cascades

    case coding_agents
    case multi_agent
    case reinforcement_learning
    case evaluation

    public var label: String {
        switch self {
        case .replay_and_forking:
            return "Replay and forking"

        case .multi_agent:
            return "Multi-agent"

        default:
            return rawValue.tagLabel
        }
    }
}

public extension ReferenceTagSet {
    static func agentic(
        _ tags: AgenticTag...
    ) -> ReferenceTagSet {
        tags.tags
    }
}
