import Testing

private enum AgenticTestingMainError: Error {
    case failed
}

@main
struct AgenticTestingMain {
    static func main() async throws {
        let reporter = PlainTextTestReporter()
        let result = await TestRunner.run(
            UnifiedAgenticTestSuite.testSuite,
            sink: reporter
        )
        let rendered = await reporter.rendered()

        if !rendered.isEmpty {
            print(
                rendered
            )
        }

        if result.isFailure {
            throw AgenticTestingMainError.failed
        }
    }
}
