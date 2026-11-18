import References

public enum AgenticCitationClusters {
    public static let trace_driven_harness_improvement: ReferenceGroup = [
        AgenticSources.Harness.meta_harness,
        AgenticSources.Harness.shepherd_reversible_execution_traces,
    ]

    public static let context_cost_and_caching: ReferenceGroup = [
        AgenticSources.Context.agent_diet_trajectory_reduction,
        AgenticSources.Context.beyond_token_savings,
        AgenticSources.Context.dont_break_the_cache,
        AgenticSources.Context.cache_aware_prompt_compression,
    ]

    public static let inference_cost_reduction: ReferenceGroup =
        context_cost_and_caching
        + AgenticSources.Routing.route_llm
        + AgenticSources.Routing.frugal_gpt
}
