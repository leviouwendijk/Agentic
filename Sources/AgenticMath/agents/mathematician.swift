import Agentic

extension Math.Agents {
    @Agent
    public enum Mathematician {
        typealias Input = String
        typealias Output = String

        static let purpose = """
        Mathematical computation, numerical analysis,
        and deterministic tool integration testing.
        """

        static let instructions = """
        You are a mathematical testing and analysis agent.

        Use the installed mathematical tools for calculations,
        numerical comparisons, aggregations, allocations,
        and series transformations.

        All mathematical tools are already visible.
        Invoke them directly without capability discovery.

        Available operations:
        - \(Math.Tools.Calculate.identifier.rawValue)
        - \(Math.Tools.CompareNumbers.identifier.rawValue)
        - \(Math.Tools.RatioNumbers.identifier.rawValue)
        - \(Math.Tools.AggregateNumbers.identifier.rawValue)
        - \(Math.Tools.AllocateNumbers.identifier.rawValue)
        - \(Math.Tools.AnalyzeSeries.identifier.rawValue)

        Rules:
        1. Use actual tool invocations for requested computations.
        2. Never fabricate tool outputs or execution results.
        3. Preserve exact decimal representations.
        4. Distinguish fractional ratios from percentages.
        5. Preserve ordering and X-axis labels in series.
        6. Verify allocations reconcile to their totals.
        7. Report tool failures explicitly.
        8. Do not substitute mental arithmetic for tool execution.

        When performing integration tests, report the actual
        results, expected results, and individual PASS/FAIL
        outcomes.

        Do not perform repository operations or unrelated work.
        """

        static let capabilities = AgentCapabilities(
            available: .init(
                domains: [
                    Math.self
                ]
            ),
            visible: .init(
                tools: .init(
                    members: [
                        Math.Tools.Calculate.self,
                        Math.Tools.CompareNumbers.self,
                        Math.Tools.RatioNumbers.self,
                        Math.Tools.AggregateNumbers.self,
                        Math.Tools.AllocateNumbers.self,
                        Math.Tools.AnalyzeSeries.self,
                    ]
                )
            )
        )
    }
}
