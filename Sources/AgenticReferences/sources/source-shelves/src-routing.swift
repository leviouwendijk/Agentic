import Primitives
import References

public extension AgenticSources {
    enum Routing: String, CaseIterable, Codable, AgenticSourceProviding {
        public static let namespace = "agentic.routing"

        // MARK: - Model routing and cascades

        case route_llm
        case frugal_gpt

        public var data: ReferenceData {
            switch self {
            case .route_llm:
                return AgenticSources.arxiv(
                    "2406.18665",
                    title: "RouteLLM: Learning to Route LLMs with Preference Data",
                    authors: AgenticSources.authors(
                        [
                            AgenticSources.author(
                                given: "Isaac",
                                family: "Ong"
                            ),
                            AgenticSources.author(
                                given: "Amjad",
                                family: "Almahairi"
                            ),
                            AgenticSources.author(
                                given: "Vincent",
                                family: "Wu"
                            ),
                            AgenticSources.author(
                                given: "Wei-Lin",
                                family: "Chiang"
                            ),
                            AgenticSources.author(
                                given: "Tianhao",
                                family: "Wu"
                            ),
                            AgenticSources.author(
                                given: "Joseph E.",
                                family: "Gonzalez"
                            ),
                            AgenticSources.author(
                                given: "M. Waleed",
                                family: "Kadous"
                            ),
                            AgenticSources.author(
                                given: "Ion",
                                family: "Stoica"
                            )
                        ]
                    ),
                    date: AgenticSources.published(
                        "2024-06-26"
                    ),
                    abstract: .summary(
                        "Trains router models on human preference data to choose, per query, between a stronger and a weaker LLM. Cuts cost by more than half in some settings without lowering response quality, and the routers keep working when the strong and weak models are swapped at test time."
                    ),
                    tags: facets
                )

            case .frugal_gpt:
                return AgenticSources.arxiv(
                    "2305.05176",
                    title: "FrugalGPT: How to Use Large Language Models While Reducing Cost and Improving Performance",
                    authors: AgenticSources.authors(
                        [
                            AgenticSources.author(
                                given: "Lingjiao",
                                family: "Chen"
                            ),
                            AgenticSources.author(
                                given: "Matei",
                                family: "Zaharia"
                            ),
                            AgenticSources.author(
                                given: "James",
                                family: "Zou"
                            )
                        ]
                    ),
                    date: AgenticSources.published(
                        "2023-05-09"
                    ),
                    abstract: .summary(
                        "Surveys three ways to reduce LLM inference cost (prompt adaptation, LLM approximation and LLM cascades) and proposes FrugalGPT, a learned cascade that picks which models to query per input. Matches the best single model with up to 98% lower cost, or improves accuracy at equal cost."
                    ),
                    tags: facets
                )
            }
        }

        public var facets: ReferenceTagSet {
            switch self {
            case .route_llm:
                return .agentic(
                    .model_routing,
                    .cost_efficiency
                )

            case .frugal_gpt:
                return .agentic(
                    .model_cascades,
                    .model_routing,
                    .cost_efficiency
                )
            }
        }
    }
}
