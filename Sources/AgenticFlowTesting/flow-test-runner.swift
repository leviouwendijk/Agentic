import Foundation

enum FlowTestRunner {
    static func main() async {
        let requested = Array(
            CommandLine.arguments.dropFirst()
        )

        if requested.contains("--help") || requested.contains("-h") {
            printUsage()
            Foundation.exit(0)
        }

        let names = requested.isEmpty || requested == ["all"]
            ? FlowTestCase.allCases.map(\.rawValue)
            : requested

        var results: [FlowTestResult] = []

        for name in names {
            guard let testCase = FlowTestCase(rawValue: name) else {
                results.append(
                    .failed(
                        name: name,
                        diagnostics: [
                            "unknown flow test '\(name)'",
                            "available: \(FlowTestCase.allCases.map(\.rawValue).joined(separator: ", "))"
                        ]
                    )
                )
                continue
            }

            results.append(
                await run(
                    testCase
                )
            )
        }

        FlowReporter.print(
            results
        )

        Foundation.exit(
            results.contains(where: \.isFailure) ? 1 : 0
        )
    }

    private static func run(
        _ testCase: FlowTestCase
    ) async -> FlowTestResult {
        do {
            switch testCase {
            case .buffered:
                return try await AgenticFlowTesting.runBuffered()

            case .stream:
                return try await AgenticFlowTesting.runStream()

            case .stream_error:
                return try await AgenticFlowTesting.runStreamError()

            case .stream_cancel:
                return try await AgenticFlowTesting.runStreamCancel()

            case .stream_tool_use:
                return try await AgenticFlowTesting.runStreamToolUse()
            }
        } catch {
            return .failed(
                name: testCase.rawValue,
                diagnostics: [
                    error.localizedDescription
                ]
            )
        }
    }

    private static func printUsage() {
        print(
            """
            usage:
              swift run flowtest
              swift run flowtest all
              swift run flowtest buffered
              swift run flowtest stream
              swift run flowtest stream-error
              swift run flowtest stream-cancel
              swift run flowtest stream-tool-use
            """
        )
    }
}
