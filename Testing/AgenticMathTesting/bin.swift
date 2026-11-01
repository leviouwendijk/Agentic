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

        Test("round-as-chained-unary-step") {
            let result = try Math.Calculation.Evaluator.evaluate(
                .init(steps: [
                    .init(
                        id: "division", operation: .divide,
                        operands: [.value("10"), .value("3")]
                    ),
                    .init(
                        id: "money", operation: .round,
                        operands: [.ref("division")],
                        rounding: .init(scale: 2, mode: .bankers)
                    ),
                ], outputs: ["division", "money"])
            )
            try Expect.equal(result.outputs[0].value, "3.333333333333", "Working decimal")
            try Expect.equal(result.outputs[1].value, "3.33", "Explicit rounding")
        }

        Test("reject-invalid-rounding-step") {
            try Expect.throwsError("Unary rounding requires a policy") {
                _ = try Math.Calculation.Evaluator.evaluate(.init(steps: [
                    .init(id: "bad", operation: .round, operands: [.value("1.23")])
                ]))
            }
            try Expect.throwsError("Non-rounding step cannot receive rounding policy") {
                _ = try Math.Calculation.Evaluator.evaluate(.init(steps: [
                    .init(id: "bad", operation: .add,
                          operands: [.value("1"), .value("2")],
                          rounding: .init(scale: 2))
                ]))
            }
        }

        Test("compare-tool-identifier") {
            try Expect.equal(
                Math.Tools.CompareNumbers.definition.identifier.rawValue,
                "compare_numbers", "Compare tool identifier"
            )
        }


        Test("ratio-and-aggregate-tool-contract") {
            try Expect.equal(Math.Tools.RatioNumbers.definition.identifier.rawValue, "ratio_numbers", "Ratio ID")
            try Expect.equal(Math.Tools.AggregateNumbers.definition.identifier.rawValue, "aggregate_numbers", "Aggregate ID")
            let result = try Math.Tools.RatioNumbers.evaluate(.init(
                operation: .percentage_change, lhs: "100", rhs: "115"
            ))
            try Expect.equal(result.value, "15", "Percentage points")
            let aggregate = try Math.Tools.AggregateNumbers.evaluate(.init(
                operation: .weighted_mean, values: ["10", "20"], weights: ["1", "3"]
            ))
            try Expect.equal(aggregate.value, "17.5", "Weighted mean via tool")
            try Expect.throwsError("Mismatch weights rejected") {
                _ = try Math.Tools.AggregateNumbers.evaluate(.init(
                    operation: .weighted_mean, values: ["10", "20"], weights: ["1"]
                ))
            }
        }


        Test("allocation-tool-reconciles") {
            try Expect.equal(Math.Tools.AllocateNumbers.definition.identifier.rawValue, "allocate_numbers", "Allocation ID")
            let output = try Math.Tools.AllocateNumbers.evaluate(.init(total: "100", weights: ["1", "1", "1"]))
            try Expect.equal(output.allocations, ["33.34", "33.33", "33.33"], "Deterministic fair remainder")
            try Expect.equal(output.reconciled_total, "100", "Exact total")
        }


        Test("plot-ready-series-tool-keeps-x-alignment") {
            try Expect.equal(Math.Tools.AnalyzeSeries.definition.identifier.rawValue, "analyze_series", "Series ID")
            let points: [Math.Tools.AnalyzeSeries.Point] = [
                .init(x: "jan", value: "10"),
                .init(x: "feb", value: "20"),
                .init(x: "mar", value: "30")
            ]
            let diff = try Math.Tools.AnalyzeSeries.evaluate(.init(operation: .difference, points: points))
            try Expect.equal(diff.points.map(\.x), ["feb", "mar"], "Difference aligned to later observations")
            try Expect.equal(diff.points.map(\.value), ["10", "10"], "Differences")
            let moving = try Math.Tools.AnalyzeSeries.evaluate(.init(operation: .moving_mean, points: points, window: 2))
            try Expect.equal(moving.points.map(\.x), ["feb", "mar"], "Moving window end alignment")
            try Expect.equal(moving.points.map(\.value), ["15", "25"], "Rolling means")
            try Expect.throwsError("Invalid rolling window rejected") {
                _ = try Math.Tools.AnalyzeSeries.evaluate(.init(operation: .moving_mean, points: points, window: 0))
            }
        }

        Test("verify-numbers-exact-and-tolerance") {
            try Expect.equal(Math.Tools.VerifyNumbers.definition.identifier.rawValue, "verify_numbers", "Tool ID")
            let exact = try Math.Tools.VerifyNumbers.evaluate(.init(
                operation: .expected, observed: "21", expected: "21"
            ))
            try Expect.equal(exact.matches, true, "Exact result")
            try Expect.equal(exact.difference, "0", "No discrepancy")

            let mismatch = try Math.Tools.VerifyNumbers.evaluate(.init(
                operation: .expected, observed: "20.99", expected: "21"
            ))
            try Expect.equal(mismatch.matches, false, "Mismatch detected")
            try Expect.equal(mismatch.difference, "-0.01", "Signed difference")

            let tolerated = try Math.Tools.VerifyNumbers.evaluate(.init(
                operation: .expected, observed: "20.99", expected: "21", tolerance: "0.01"
            ))
            try Expect.equal(tolerated.matches, true, "Inclusive tolerance")
        }

        Test("verify-numbers-percentage-rounding") {
            let fraction = try Math.Tools.VerifyNumbers.evaluate(.init(
                operation: .percentage, observed: "0.10", base: "80", rate: "0.125", scale: 2
            ))
            try Expect.equal(fraction.expected, "0.1", "Fractional percentage points")
            try Expect.equal(fraction.matches, true, "Fractional percentage matches")

            let plain = try Math.Tools.VerifyNumbers.evaluate(.init(
                operation: .percentage, observed: "0.33", base: "1", rate: "32.5", scale: 2
            ))
            let bankers = try Math.Tools.VerifyNumbers.evaluate(.init(
                operation: .percentage, observed: "0.32", base: "1", rate: "32.5", scale: 2, rounding: .bankers
            ))
            try Expect.equal(plain.expected, "0.33", "Plain half-up rounding")
            try Expect.equal(bankers.expected, "0.32", "Bankers tie-to-even rounding")
            let aggregated = try Math.Tools.VerifyNumbers.evaluate(.init(
                operation: .percentage, observed: "0.67", base: "2", rate: "33.5", scale: 2
            ))
            try Expect.equal(aggregated.expected, "0.67", "Aggregate rounds at final boundary")
        }

        Test("verify-numbers-reject-invalid-contracts") {
            try Expect.throwsError("Expected operation forbids percentage fields") {
                _ = try Math.Tools.VerifyNumbers.evaluate(.init(
                    operation: .expected, observed: "1", expected: "1", rate: "2"
                ))
            }
            try Expect.throwsError("Percentage requires explicit scale") {
                _ = try Math.Tools.VerifyNumbers.evaluate(.init(
                    operation: .percentage, observed: "1", base: "10", rate: "10"
                ))
            }
            try Expect.throwsError("Negative tolerance is invalid") {
                _ = try Math.Tools.VerifyNumbers.evaluate(.init(
                    operation: .expected, observed: "1", expected: "1", tolerance: "-0.01"
                ))
            }
            try Expect.throwsError("Invalid decimal literal rejected") {
                _ = try Math.Tools.VerifyNumbers.evaluate(.init(
                    operation: .percentage, observed: "1", base: "garbage", rate: "10", scale: 2
                ))
            }
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
