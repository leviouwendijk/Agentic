import Agentic
import Foundation
import Testing

public enum AssertionRunnerError: Error, Sendable, Equatable {
    case empty_assertions
    case excessive_assertions
    case duplicate_id(String)
    case empty_id
    case unsupported_subject(String)
    case invalid_expectation(String)
}

private actor AssertionResultCollector {
    private var collected: [String: AssertionResult] = [:]

    func record(_ result: AssertionResult) {
        collected[result.id] = result
    }

    func result(id: String) -> AssertionResult? {
        collected[id]
    }
}

/// Compiles declarative assertions into actual Testing.Test nodes.
public struct AssertionRunner: Sendable {
    public let providers: [any AssertionObservationProvider]

    public init(
        providers: [any AssertionObservationProvider] = [
            LiteralTextAssertionProvider(),
            WorkspaceFileAssertionProvider()
        ]
    ) {
        self.providers = providers
    }

    public func validate(_ assertions: [Assertion]) throws {
        guard !assertions.isEmpty else { throw AssertionRunnerError.empty_assertions }
        guard assertions.count <= 32 else { throw AssertionRunnerError.excessive_assertions }
        var seen = Set<String>()
        for assertion in assertions {
            guard !assertion.id.isEmpty else { throw AssertionRunnerError.empty_id }
            guard seen.insert(assertion.id).inserted else {
                throw AssertionRunnerError.duplicate_id(assertion.id)
            }
            guard providers.contains(where: { $0.kind == assertion.subject.kind }) else {
                throw AssertionRunnerError.unsupported_subject(assertion.subject.kind)
            }
            let expectation = assertion.expect
            switch expectation.operation {
            case .exists, .absent:
                guard assertion.subject.kind == "workspace_file" else {
                    throw AssertionRunnerError.invalid_expectation(assertion.id)
                }
            case .equals, .contains, .not_contains:
                guard expectation.value != nil else {
                    throw AssertionRunnerError.invalid_expectation(assertion.id)
                }
            case .match_count:
                guard let value = expectation.value, !value.isEmpty,
                      let count = expectation.count, count >= 0 else {
                    throw AssertionRunnerError.invalid_expectation(assertion.id)
                }
            case .line_range_exists:
                guard assertion.subject.kind == "workspace_file",
                      let start = expectation.startLine, start > 0,
                      let end = expectation.endLine, end >= start else {
                    throw AssertionRunnerError.invalid_expectation(assertion.id)
                }
            }
        }
    }

    public func run(
        _ assertions: [Assertion],
        in context: ToolContext
    ) async throws -> AssertionReport {
        try validate(assertions)
        let collector = AssertionResultCollector()
        let children: [TestNode] = assertions.map { assertion in
            .test(Test(assertion.id) { testContext in
                let observation = await observe(assertion.subject, in: context)
                let result = evaluate(assertion, observation: observation)
                await collector.record(result)
                await testContext.expect(
                    result.status == .satisfied,
                    result.message
                )
            })
        }
        let suite = TestSuite("agentic-assertions", children: children)
        let run = await TestRunner.run(suite)
        var ordered: [AssertionResult] = []
        for assertion in assertions {
            if let result = await collector.result(id: assertion.id) {
                ordered.append(result)
            } else {
                ordered.append(.init(
                    id: assertion.id,
                    status: .unavailable,
                    message: "Assertion was not executed by Testing"
                ))
            }
        }
        // Every Testing node must have executed. Ordinary failed expectations
        // represent unsatisfied assertions, not unavailable evidence.
        let executedExactly = run.results.count == assertions.count
            && zip(run.results, assertions).allSatisfy { test, assertion in
                test.test.id == assertion.id
                    && (test.outcome == .passed || test.outcome == .failed)
            }
        let status: AssertionStatus
        if ordered.contains(where: { $0.status == .unavailable }) || !executedExactly {
            status = .unavailable
        } else if ordered.allSatisfy({ $0.status == .satisfied }) {
            status = .satisfied
        } else {
            status = .unsatisfied
        }
        return .init(status: status, results: ordered)
    }

    private func observe(
        _ subject: Assertion.Subject,
        in context: ToolContext
    ) async -> AssertionObservation {
        guard let provider = providers.first(where: { $0.kind == subject.kind }) else {
            return .init(error: "No registered provider for \(subject.kind)")
        }
        return await provider.observe(subject, in: context)
    }

    private func evaluate(
        _ assertion: Assertion,
        observation: AssertionObservation
    ) -> AssertionResult {
        let expectation = assertion.expect
        // Existence remains evaluable when the existing file is too large,
        // non-textual, or otherwise unsuitable for content inspection.
        let existenceOnly = expectation.operation == .exists || expectation.operation == .absent
        if let error = observation.error, !(existenceOnly && observation.exists != nil) {
            return .init(id: assertion.id, status: .unavailable, message: error)
        }
        let expected = expectation.value
        let actual = observation.text
        let matched: Bool
        switch expectation.operation {
        case .exists:
            matched = observation.exists == true
        case .absent:
            matched = observation.exists == false
        case .equals:
            matched = actual == expected
        case .contains:
            matched = actual?.contains(expected ?? "") == true
        case .not_contains:
            matched = actual?.contains(expected ?? "") == false && actual != nil
        case .match_count:
            guard let actual, let expected, !expected.isEmpty else {
                return .init(
                    id: assertion.id, status: .unsatisfied,
                    message: "No text available for match count", expected: expected
                )
            }
            matched = actual.components(separatedBy: expected).count - 1 == expectation.count
        case .line_range_exists:
            matched = observation.exists == true
                && (observation.lineCount ?? 0) >= (expectation.endLine ?? Int.max)
        }
        return .init(
            id: assertion.id,
            status: matched ? .satisfied : .unsatisfied,
            message: matched ? "Condition satisfied" : "Condition was not satisfied",
            expected: expected,
            actual: actual.map { String($0.prefix(256)) }
        )
    }
}
