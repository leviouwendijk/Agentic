import Primitives
import References

public extension AgenticSources {
    enum Context: String, CaseIterable, Codable, AgenticSourceProviding {
        public static let namespace = "agentic.context"

        // MARK: - Trajectory reduction and compression

        case agent_diet_trajectory_reduction
        case beyond_token_savings

        // MARK: - Prompt caching

        case dont_break_the_cache
        case cache_aware_prompt_compression

        public var data: ReferenceData {
            switch self {
            case .agent_diet_trajectory_reduction:
                return AgenticSources.arxiv(
                    "2509.23586",
                    title: "Reducing Cost of LLM Agents with Trajectory Reduction",
                    authors: AgenticSources.authors(
                        [
                            AgenticSources.author(
                                given: "Yuan-An",
                                family: "Xiao"
                            ),
                            AgenticSources.author(
                                given: "Pengfei",
                                family: "Gao"
                            ),
                            AgenticSources.author(
                                given: "Chao",
                                family: "Peng"
                            ),
                            AgenticSources.author(
                                given: "Yingfei",
                                family: "Xiong"
                            )
                        ]
                    ),
                    date: AgenticSources.published(
                        "2025-09-28"
                    ),
                    abstract: .summary(
                        "Introduces AgentDiet, an inference-time approach that removes useless, redundant and expired information from a coding agent's trajectory during execution. Reduces input tokens by 39.9-59.7% and total computational cost by 21.1-35.9% without loss of agent performance."
                    ),
                    notes: [
                        .note(
                            "Evidence that much of a long trajectory is waste that can be pruned while the agent runs, not only summarized after the fact."
                        )
                    ],
                    tags: facets
                )

            case .beyond_token_savings:
                return AgenticSources.arxiv(
                    "2609.32961",
                    title: "Beyond Token Savings: A Systematic Study of Context Compression in LLM Agents",
                    authors: AgenticSources.authors(
                        [
                            AgenticSources.author(
                                given: "Ritul",
                                family: "Satish"
                            ),
                            AgenticSources.author(
                                given: "Prasoon",
                                family: "Sinha"
                            ),
                            AgenticSources.author(
                                given: "Akiho",
                                family: "Kawada"
                            ),
                            AgenticSources.author(
                                given: "Neeraja J.",
                                family: "Yadwadkar"
                            )
                        ]
                    ),
                    date: AgenticSources.published(
                        "2026-09-26"
                    ),
                    abstract: .summary(
                        "Separates what, when and how much to compress in agent histories, and varies each across three open-weight models on SWE-bench Verified and Terminal-Bench 1.0 in about 35,000 runs. Fewer tokens need not mean faster or cheaper execution: some policies using a third of the tokens take 20-80% longer, and policies with similar success solve different tasks."
                    ),
                    notes: [
                        .note(
                            "Use as a caution against judging compression by token count alone; evaluate by task success, latency and cost, per model and workload."
                        )
                    ],
                    tags: facets
                )

            case .dont_break_the_cache:
                return AgenticSources.arxiv(
                    "2601.06007",
                    title: "Don't Break the Cache: An Evaluation of Prompt Caching for Long-Horizon Agentic Tasks",
                    authors: AgenticSources.authors(
                        [
                            AgenticSources.author(
                                given: "Elias",
                                family: "Lumer"
                            ),
                            AgenticSources.author(
                                given: "Faheem",
                                family: "Nizar"
                            ),
                            AgenticSources.author(
                                given: "Akshaya",
                                family: "Jangiti"
                            ),
                            AgenticSources.author(
                                given: "Kevin",
                                family: "Frank"
                            ),
                            AgenticSources.author(
                                given: "Anmol",
                                family: "Gulati"
                            ),
                            AgenticSources.author(
                                given: "Mandar",
                                family: "Phadate"
                            ),
                            AgenticSources.author(
                                given: "Vamse Kumar",
                                family: "Subbiah"
                            )
                        ]
                    ),
                    date: AgenticSources.published(
                        "2026-01-09"
                    ),
                    abstract: .summary(
                        "Evaluates prompt caching across OpenAI, Anthropic and Google on a multi-turn agentic research benchmark, comparing full-context caching, system-prompt-only caching and caching that excludes dynamic tool results. Caching cuts API cost by 41-80% and time to first token by 13-31%; deliberate cache-block placement beats naive full-context caching."
                    ),
                    notes: [
                        .note(
                            "Practical guidance for prompt layout: keep dynamic content at the end, avoid dynamic tool definitions, and keep volatile tool results out of the cached prefix."
                        )
                    ],
                    tags: facets
                )

            case .cache_aware_prompt_compression:
                return AgenticSources.arxiv(
                    "2607.15516",
                    title: "Cache-Aware Prompt Compression: A Two-Tier Cost Model for LLM API Caching",
                    authors: AgenticSources.authors(
                        [
                            AgenticSources.author(
                                given: "Yan",
                                family: "Song"
                            )
                        ]
                    ),
                    date: AgenticSources.published(
                        "2026-07-17"
                    ),
                    abstract: .summary(
                        "Shows that query-aware prompt compression invalidates prefix caches on every call, and models the trade-off under measured (not ideal) cache hit rates. Proposes CAPC: query-agnostic compression with explicit cache control and a ratio bound that keeps the cached prefix stable, which was the cheapest strategy in all tested configurations at near-baseline quality."
                    ),
                    notes: [
                        .note(
                            "Relevant whenever compression and caching are combined: compression that changes the prefix can cost more than it saves."
                        )
                    ],
                    tags: facets
                )
            }
        }

        public var facets: ReferenceTagSet {
            switch self {
            case .agent_diet_trajectory_reduction:
                return .agentic(
                    .context_management,
                    .trajectory_reduction,
                    .cost_efficiency,
                    .coding_agents
                )

            case .beyond_token_savings:
                return .agentic(
                    .context_management,
                    .context_compression,
                    .cost_efficiency,
                    .latency,
                    .coding_agents,
                    .evaluation
                )

            case .dont_break_the_cache:
                return .agentic(
                    .context_management,
                    .prompt_caching,
                    .cost_efficiency,
                    .latency,
                    .evaluation
                )

            case .cache_aware_prompt_compression:
                return .agentic(
                    .context_compression,
                    .prompt_caching,
                    .cost_efficiency
                )
            }
        }
    }
}
