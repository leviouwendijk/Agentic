import Primitives
import References

public extension AgenticSources {
    enum Harness: String, CaseIterable, Codable, AgenticSourceProviding {
        public static let namespace = "agentic.harness"

        // MARK: - Meta-agents and execution traces

        case shepherd_reversible_execution_traces

        // MARK: - Harness optimization

        case meta_harness

        public var data: ReferenceData {
            switch self {
            case .shepherd_reversible_execution_traces:
                return AgenticSources.arxiv(
                    "2605.10913",
                    title: "Shepherd: Enabling Programmable Meta-Agents via Reversible Agentic Execution Traces",
                    authors: AgenticSources.authors(
                        [
                            AgenticSources.author(
                                given: "Simon",
                                family: "Yu"
                            ),
                            AgenticSources.author(
                                given: "Derek",
                                family: "Chong"
                            ),
                            AgenticSources.author(
                                given: "Ananjan",
                                family: "Nandi"
                            ),
                            AgenticSources.author(
                                given: "Dilara",
                                family: "Soylu"
                            ),
                            AgenticSources.author(
                                given: "Jiuding",
                                family: "Sun"
                            ),
                            AgenticSources.author(
                                given: "Christopher D.",
                                family: "Manning"
                            ),
                            AgenticSources.author(
                                given: "Weiyan",
                                family: "Shi"
                            )
                        ]
                    ),
                    date: AgenticSources.published(
                        "2026-05-11"
                    ),
                    abstract: .summary(
                        "A runtime substrate in which an agent's execution is a first-class object: every model action, tool call and environment change becomes a structured event in a reversible, Git-like execution trace. Meta-agents can inspect, revert, fork and replay that trace, which the authors use for supervising parallel coding agents, counterfactual workflow repair and choosing fork points for credit assignment in agentic RL."
                    ),
                    notes: [
                        .note(
                            "Relevant to Agentic's session and history design: a formalized execution trace as the substrate for state forking, replay from a changed point and runtime intervention by a supervising agent."
                        )
                    ],
                    tags: facets
                )

            case .meta_harness:
                return AgenticSources.arxiv(
                    "2603.28052",
                    title: "Meta-Harness: End-to-End Optimization of Model Harnesses",
                    authors: AgenticSources.authors(
                        [
                            AgenticSources.author(
                                given: "Yoonho",
                                family: "Lee"
                            ),
                            AgenticSources.author(
                                given: "Roshen",
                                family: "Nair"
                            ),
                            AgenticSources.author(
                                given: "Qizheng",
                                family: "Zhang"
                            ),
                            AgenticSources.author(
                                given: "Kangwook",
                                family: "Lee"
                            ),
                            AgenticSources.author(
                                given: "Omar",
                                family: "Khattab"
                            ),
                            AgenticSources.author(
                                given: "Chelsea",
                                family: "Finn"
                            )
                        ]
                    ),
                    date: AgenticSources.published(
                        "2026-03-30"
                    ),
                    abstract: .summary(
                        "An outer-loop system that searches over harness code: the code deciding what to store, retrieve and present to the model. An agentic proposer reads the source, scores and execution traces of all prior candidates through a filesystem, and the discovered harnesses beat hand-engineered baselines on text classification, retrieval-augmented math reasoning and TerminalBench-2."
                    ),
                    notes: [
                        .note(
                            "Relevant to autonomous harness improvement: argues that optimizers need rich access to prior experiments and traces rather than compressed feedback."
                        )
                    ],
                    tags: facets
                )
            }
        }

        public var facets: ReferenceTagSet {
            switch self {
            case .shepherd_reversible_execution_traces:
                return .agentic(
                    .meta_agents,
                    .execution_traces,
                    .replay_and_forking,
                    .runtime_intervention,
                    .harness_optimization,
                    .coding_agents,
                    .multi_agent,
                    .reinforcement_learning
                )

            case .meta_harness:
                return .agentic(
                    .harness,
                    .harness_optimization,
                    .execution_traces,
                    .context_management,
                    .coding_agents
                )
            }
        }
    }
}
