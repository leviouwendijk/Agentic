import ANSI
import Terminal

enum FlowReporter {
    static func print(
        _ results: [FlowTestResult]
    ) {
        let width = max(
            16,
            (results.map(\.name.count).max() ?? 0) + 2
        )

        Swift.print(
            Style.bold(
                "Agentic flow tests"
            )
        )
        Swift.print(
            String(
                repeating: "-",
                count: max(
                    32,
                    width + 24
                )
            )
        )

        for result in results {
            switch result {
            case .passed(let name, let diagnostics):
                Swift.print(
                    "\(Style.pass("pass")) \(padded(name, width: width)) \(diagnostics.first ?? "")"
                )

                for line in diagnostics.dropFirst() {
                    Swift.print(
                        "     \(padded("", width: width)) \(Style.dim(line))"
                    )
                }

            case .failed(let name, let diagnostics):
                Swift.print(
                    "\(Style.fail("fail")) \(padded(name, width: width)) \(diagnostics.first ?? "")"
                )

                for line in diagnostics.dropFirst() {
                    Swift.print(
                        "     \(padded("", width: width)) \(Style.dim(line))"
                    )
                }
            }
        }

        let failedCount = results.filter(\.isFailure).count
        let passedCount = results.count - failedCount

        Swift.print(
            String(
                repeating: "-",
                count: max(
                    32,
                    width + 24
                )
            )
        )

        if failedCount == 0 {
            Swift.print(
                "\(Style.pass("pass")) \(passedCount)/\(results.count)"
            )
        } else {
            Swift.print(
                "\(Style.fail("fail")) \(failedCount)/\(results.count) failed, \(passedCount) passed"
            )
        }
    }

    private static func padded(
        _ value: String,
        width: Int
    ) -> String {
        value.padding(
            toLength: width,
            withPad: " ",
            startingAt: 0
        )
    }
}

private enum Style {
    private static let escape = "\u{001B}["
    private static let reset = "\(escape)0m"

    static func bold(
        _ value: String
    ) -> String {
        "\(escape)1m\(value)\(reset)"
    }

    static func pass(
        _ value: String
    ) -> String {
        "\(escape)1;32m\(value)\(reset)"
    }

    static func fail(
        _ value: String
    ) -> String {
        "\(escape)1;31m\(value)\(reset)"
    }

    static func dim(
        _ value: String
    ) -> String {
        "\(escape)2m\(value)\(reset)"
    }
}
