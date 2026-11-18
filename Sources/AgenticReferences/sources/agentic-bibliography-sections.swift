import References

public enum AgenticBibliographySections {
    public static let docsDefault: [ReferenceTagSection] = [
        ReferenceTagSection(
            id: "harness_and_meta_agents",
            title: "Harnesses, meta-agents and execution traces",
            eyebrow: "Harness",
            caption: "Sources on harness design and optimization, meta-agents, formalized execution traces, replay, forking and runtime intervention.",
            include: .agentic(
                .harness,
                .harness_optimization,
                .meta_agents,
                .execution_traces,
                .replay_and_forking,
                .runtime_intervention
            ),
            match: .any,
            sort: .date_newest
        ),

        ReferenceTagSection(
            id: "context_and_caching",
            title: "Context management and prompt caching",
            eyebrow: "Context",
            caption: "Sources on trajectory reduction, context compression, prompt caching and their effect on agent success, latency and cost.",
            include: .agentic(
                .context_management,
                .context_compression,
                .trajectory_reduction,
                .prompt_caching
            ),
            match: .any,
            sort: .date_newest
        ),

        ReferenceTagSection(
            id: "routing_and_cost",
            title: "Model routing and inference cost",
            eyebrow: "Routing",
            caption: "Sources on routing between models of different capability, model cascades and inference cost reduction.",
            include: .agentic(
                .model_routing,
                .model_cascades
            ),
            match: .any,
            sort: .date_newest
        ),
    ]
}
