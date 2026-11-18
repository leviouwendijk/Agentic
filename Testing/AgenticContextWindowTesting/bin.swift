import Agentic
import AgenticContextWindow
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
        title: "AgenticContextWindow deterministic allocator tests"
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

        Test(
            "rendered-results",
            tags: ["context", "history", "rendering"]
        ) { context in
            await context.record(
                contentsOf: try ContextDeterministicFlowTesting.runRenderedResults()
            )
        }

        Test(
            "repeated-result-pointers",
            tags: ["context", "history", "dedupe"]
        ) { context in
            await context.record(
                contentsOf: try ContextDeterministicFlowTesting.runRepeatedResultPointers()
            )
        }

        Test(
            "history-elision",
            tags: ["context", "history", "budget", "elision"]
        ) { context in
            await context.record(
                contentsOf: try ContextDeterministicFlowTesting.runHistoryElision()
            )
        }

        Test(
            "incident-history-baseline",
            tags: ["context", "history", "incident"]
        ) { context in
            await context.record(
                contentsOf: try ContextDeterministicFlowTesting.runIncidentBaseline()
            )
        }

        Test(
            "incident-followup-continuity",
            tags: ["context", "history", "incident"]
        ) {
            try ContextDeterministicFlowTesting.runIncidentContinuity()
        }

        Test("append-only-prefix", tags: ["context", "history", "cache"]) {
            try ContextDeterministicFlowTesting.runAppendOnlyPrefix()
        }

        Test("append-only-pressure", tags: ["context", "history", "pressure"]) {
            try ContextDeterministicFlowTesting.runAppendOnlyPressure()
        }

        Test("compaction-pointers", tags: ["context", "history", "compaction"]) {
            try ContextDeterministicFlowTesting.runCompaction()
        }

        Test(
            "incident-refuses-rather-than-drops",
            tags: ["context", "history", "incident"]
        ) {
            try ContextDeterministicFlowTesting.runIncidentRefusesRatherThanDrops()
        }

        Test(
            "incident-replay-measurement",
            tags: ["context", "measurement", "incident"]
        ) { context in
            await context.record(
                contentsOf: try ContextDeterministicFlowTesting.runIncidentReplayMeasurement()
            )
        }

        Test(
            "finding-provenance-and-invalidation",
            tags: ["context", "evidence", "revision"]
        ) { context in
            await context.record(
                contentsOf: try await ContextDeterministicFlowTesting.runFindingLifecycle()
            )
        }
        Test(
            "bounded-preparation-program",
            tags: ["context", "program", "budget"]
        ) { context in
            await context.record(
                contentsOf: try await ContextDeterministicFlowTesting.runBoundedPreparation()
            )
        }
    }
}
