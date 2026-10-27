import AgenticMath
import Testing

private enum AgenticMathTestingFailure: Error {
    case failed
}

@main
struct AgenticMathTestingMain {
    static func main() async throws {
        let reporter = PlainTextTestReporter()
        let result = await TestRunner.run(
            AgenticMathTestSuite.testSuite,
            sink: reporter
        )
        let rendered = await reporter.rendered()
        if !rendered.isEmpty {
            print(rendered)
        }
        if result.isFailure {
            throw AgenticMathTestingFailure.failed
        }
    }
}

enum AgenticMathTestSuite {
    static let testSuite = TestSuite(
        "agentic-math",
        title: "AgenticMath calculate tool"
    ) {
        Test("calculate-chained-references") {
            let input = Math.Tools.Calculate.Input(
                steps: [
                    .init(
                        id: "discounted",
                        operation: .multiply,
                        operands: [.value("1270"), .value("0.85")]
                    ),
                    .init(
                        id: "taxed",
                        operation: .multiply,
                        operands: [.ref("discounted"), .value("1.21")]
                    ),
                    .init(
                        id: "installment",
                        operation: .divide,
                        operands: [.ref("taxed"), .value("3")]
                    ),
                ],
                outputs: ["installment"]
            )

            let result = try Math.Calculation.Evaluator.evaluate(input)
            try Expect.equal(result.results.count, 3, "Three steps executed")
            try Expect.equal(
                result.outputs.map(\.id),
                ["installment"],
                "Selected output is preserved"
            )
            try Expect.equal(
                result.outputs.first?.value,
                "435.398333333333",
                "Chained calculation value"
            )
            try Expect.equal(
                Math.Tools.Calculate.definition.identifier.rawValue,
                "calculate",
                "Tool identifier"
            )
        }

        Test("reject-forward-reference") {
            try Expect.throwsError("Reject future step reference") {
                _ = try Math.Calculation.Evaluator.evaluate(
                    .init(steps: [
                        .init(
                            id: "first",
                            operation: .add,
                            operands: [.ref("later"), .value("3")]
                        ),
                    ])
                )
            }
        }

        Test("reject-ambiguous-operand") {
            try Expect.throwsError("Operand must be literal or reference, not both") {
                _ = try Math.Calculation.Evaluator.evaluate(
                    .init(steps: [
                        .init(
                            id: "first",
                            operation: .add,
                            operands: [
                                .init(literal: "1", reference: "other"),
                                .value("2"),
                            ]
                        ),
                    ])
                )
            }
        }
    }
}
