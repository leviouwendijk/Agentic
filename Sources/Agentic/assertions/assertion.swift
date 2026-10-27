import Foundation
import Macros
import Schema

/// A serializable expectation. Evaluation is delegated to installed evidence providers.
@JSONSchema
public struct Assertion: Sendable, Codable, Hashable {
    public let id: String
    public let subject: Subject
    public let expect: Expectation

    public init(id: String, subject: Subject, expect: Expectation) {
        self.id = id
        self.subject = subject
        self.expect = expect
    }

    @JSONSchema
    public struct Subject: Sendable, Codable, Hashable {
        /// Registered subject kind, initially literal_text or workspace_file.
        public let kind: String
        /// Literal text or a path relative to the invocation workspace.
        public let value: String

        public init(kind: String, value: String) {
            self.kind = kind
            self.value = value
        }
    }

    @JSONSchema
    public struct Expectation: Sendable, Codable, Hashable {
        @JSONSchema
        public enum Operation: String, Sendable, Codable, Hashable, CaseIterable {
            case exists
            case absent
            case equals
            case contains
            case not_contains
            case match_count
            case line_range_exists
        }

        public let operation: Operation
        /// Literal expected text for equals, contains, not_contains, or match_count.
        public let value: String?
        /// Required only for match_count.
        public let count: Int?
        /// Inclusive 1-based bounds for line_range_exists.
        public let startLine: Int?
        public let endLine: Int?

        public init(
            operation: Operation,
            value: String? = nil,
            count: Int? = nil,
            startLine: Int? = nil,
            endLine: Int? = nil
        ) {
            self.operation = operation
            self.value = value
            self.count = count
            self.startLine = startLine
            self.endLine = endLine
        }
    }
}

@JSONSchema
public enum AssertionStatus: String, Sendable, Codable, Hashable, CaseIterable {
    case satisfied
    case unsatisfied
    case unavailable
}

@JSONSchema
public struct AssertionResult: Sendable, Codable, Hashable {
    public let id: String
    public let status: AssertionStatus
    public let message: String
    public let expected: String?
    public let actual: String?

    public init(
        id: String,
        status: AssertionStatus,
        message: String,
        expected: String? = nil,
        actual: String? = nil
    ) {
        self.id = id
        self.status = status
        self.message = message
        self.expected = expected
        self.actual = actual
    }
}

@JSONSchema
public struct AssertionReport: Sendable, Codable, Hashable {
    public let status: AssertionStatus
    public let results: [AssertionResult]

    public init(status: AssertionStatus, results: [AssertionResult]) {
        self.status = status
        self.results = results
    }
}

public struct AssertionSet: Sendable, Codable, Hashable {
    public let id: String
    public let revision: Int
    public let assertions: [Assertion]
    public let frozen: Bool
    public let hash: String

    public init(
        id: String,
        revision: Int,
        assertions: [Assertion],
        frozen: Bool,
        hash: String
    ) {
        self.id = id
        self.revision = revision
        self.assertions = assertions
        self.frozen = frozen
        self.hash = hash
    }
}
