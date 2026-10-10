import Agentic
import AgenticContext
import Testing

private enum ContextTestError: Error {
    case failed
}

@main
struct ContextTestMain {
    static func main() async throws {
        let reporter = PlainTextTestReporter()
        let result = await TestRunner.run(
            ContextDeterministicTestSuite.testSuite,
            sink: reporter
        )
        let rendered = await reporter.rendered()

        if !rendered.isEmpty {
            print(rendered)
        }

        if result.isFailure {
            throw ContextTestError.failed
        }
    }
}

enum ContextDeterministicFlowTesting {}

enum ContextDeterministicTestSuite {
    static let testSuite = TestSuite(
        "agentic-context",
        title: "AgenticContext deterministic allocator tests"
    ) {
        Test(
            "allocator-working-sets",
            tags: ["context", "deterministic", "isolation"]
        ) { context in
            await context.record(
                contentsOf: try await ContextDeterministicFlowTesting.runContextAllocator()
            )
        }

        Test(
            "dynamic-vs-accumulating",
            tags: ["context", "history", "budget"]
        ) { context in
            await context.record(
                contentsOf: try await ContextDeterministicFlowTesting.runHistoryPolicies()
            )
        }
    }
}
