import Agentic
import AgenticAssertions
import Foundation
import Testing

private enum AssertionTestingFailure: Error { case failed }

@main
struct AssertionTestingMain {
    static func main() async throws {
        let reporter = PlainTextTestReporter()
        let result = await TestRunner.run(AssertionTestSuite.suite, sink: reporter)
        let output = await reporter.rendered()
        if !output.isEmpty { print(output) }
        if result.isFailure { throw AssertionTestingFailure.failed }
    }
}

enum AssertionTestSuite {
    static let suite = TestSuite("agentic-assertions") {
        Test("literal-passing-and-failing") {
            let runner = AssertionRunner()
            let report = try await runner.run([
                .init(
                    id: "pass",
                    subject: .init(kind: "literal_text", value: "alpha beta"),
                    expect: .init(operation: .contains, value: "beta")
                ),
                .init(
                    id: "fail",
                    subject: .init(kind: "literal_text", value: "alpha beta"),
                    expect: .init(operation: .equals, value: "gamma")
                )
            ], in: .init())
            try Expect.equal(report.status, .unsatisfied, "Overall condition must fail")
            try Expect.equal(report.results[0].status, .satisfied, "First passed")
            try Expect.equal(report.results[1].status, .unsatisfied, "Second failed")
        }

        Test("workspace-unavailable-not-absent") {
            let report = try await AssertionRunner().run([
                .init(
                    id: "unavailable",
                    subject: .init(kind: "workspace_file", value: "unknown.swift"),
                    expect: .init(operation: .absent)
                )
            ], in: .init())
            try Expect.equal(report.status, .unavailable, "No workspace is not absence")
        }

        Test("duplicate-identifiers-rejected") {
            try Expect.throwsError("Duplicate IDs") {
                try AssertionRunner().validate([
                    .init(id: "same", subject: .init(kind: "literal_text", value: "a"), expect: .init(operation: .equals, value: "a")),
                    .init(id: "same", subject: .init(kind: "literal_text", value: "b"), expect: .init(operation: .equals, value: "b"))
                ])
            }
        }

        Test("revision-cas-and-freeze") {
            let store = AssertionSetStore()
            let assertions: [Assertion] = [
                .init(id: "one", subject: .init(kind: "literal_text", value: "x"), expect: .init(operation: .equals, value: "x"))
            ]
            let first = try await store.define(id: "acceptance", expectedRevision: nil, assertions: assertions, freeze: false)
            try Expect.equal(first.revision, 1, "Creation revision")
            let frozen = try await store.define(id: "acceptance", expectedRevision: 1, assertions: assertions, freeze: true)
            try Expect.equal(frozen.revision, 2, "Updated revision")
            try Expect.equal(frozen.frozen, true, "Frozen set")
            let previous = try await store.load(id: "acceptance", revision: 1)
            try Expect.equal(previous?.revision, 1, "Old pinned revision remains accessible")
            do {
                _ = try await store.define(id: "acceptance", expectedRevision: 2, assertions: assertions, freeze: false)
                throw AssertionTestingFailure.failed
            } catch AssertionSetStoreError.frozen {
                // Expected immutable frozen revision.
            }
        }

        Test("durable-revisions-reload") {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("assertion-store-\(UUID().uuidString)", isDirectory: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let assertions: [Assertion] = [
                .init(
                    id: "one", subject: .init(kind: "literal_text", value: "ok"),
                    expect: .init(operation: .equals, value: "ok")
                )
            ]
            let original = AssertionSetStore(directory: directory)
            let created = try await original.define(
                id: "durable", expectedRevision: nil,
                assertions: assertions, freeze: false
            )
            _ = try await original.define(
                id: "durable", expectedRevision: 1,
                assertions: assertions, freeze: true
            )
            let reopened = AssertionSetStore(directory: directory)
            let earlier = try await reopened.load(id: "durable", revision: 1)
            let latest = try await reopened.load(id: "durable")
            try Expect.equal(earlier?.hash, created.hash, "Pinned revision survives restart")
            try Expect.equal(latest?.revision, 2, "Latest revision survives restart")
        }

        Test("file-assertion-preflight-escalates-risk") {
            let input = Assertions.Tools.Evaluate.Input(assertions: [
                .init(
                    id: "file", subject: .init(kind: "workspace_file", value: "Package.swift"),
                    expect: .init(operation: .exists)
                )
            ])
            let review = try await Assertions.Tools.Evaluate().preflight(input, in: .init())
            try Expect.equal(review.risk, .privileged, "File reads require explicit risk review")
        }

        Test("typed-tools-share-set-store") {
            let store = AssertionSetStore()
            let assertions: [Assertion] = [
                .init(
                    id: "equality",
                    subject: .init(kind: "literal_text", value: "ready"),
                    expect: .init(operation: .equals, value: "ready")
                )
            ]
            let created = try await Assertions.Tools.DefineSet(store: store).call(
                .init(id: "shared", assertions: assertions), in: .init()
            )
            let inspected = try await Assertions.Tools.InspectSet(store: store).call(
                .init(id: "shared"), in: .init()
            )
            try Expect.equal(created.revision, inspected.revision, "Revision shared")
            let evaluated = try await Assertions.Tools.EvaluateSet(store: store).call(
                .init(id: "shared", revision: created.revision, hash: created.hash),
                in: .init()
            )
            try Expect.equal(evaluated.report.status, .satisfied, "Stored assertion evaluated")
        }

        Test("tool-identity") {
            try Expect.equal(Assertions.Tools.Evaluate.definition.identifier.rawValue, "assertions.evaluate", "Evaluate identifier")
            try Expect.equal(Assertions.Tools.DefineSet.definition.identifier.rawValue, "assertions.define_set", "Define identifier")
            try Expect.equal(Assertions.Tools.EvaluateSet.definition.identifier.rawValue, "assertions.evaluate_set", "Run identifier")
            try Expect.equal(Assertions.Tools.InspectSet.definition.identifier.rawValue, "assertions.inspect_set", "Inspect identifier")
        }
    }
}
