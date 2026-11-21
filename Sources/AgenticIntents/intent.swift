import Agentic
import Foundation
import Macros
import Primitives
import Schema

public extension Intents {
    /// One tool call, prepared during review and stored until a person
    /// decides on it.
    @JSONSchema
    struct Intent: Sendable, Codable, Hashable, Identifiable {
        public let id: ID
        /// The session whose run deferred the call.
        public var sessionID: String?
        /// The reviewed call and the exact operation it will execute.
        public var invocation: ToolInvocation.Prepared
        public var status: Status
        public var expiresAt: Date?
        public var createdAt: Date
        public var updatedAt: Date
        public var review: Review?
        /// Written before the call runs. One left behind without a record
        /// means the run was interrupted; it is never retried.
        public var attempt: Execution.Attempt?
        public var execution: Execution.Record?
        public var metadata: [String: String]

        public init(
            id: ID = .generate(),
            sessionID: String? = nil,
            invocation: ToolInvocation.Prepared,
            status: Status = .pending,
            expiresAt: Date? = nil,
            createdAt: Date = Date(),
            updatedAt: Date = Date(),
            review: Review? = nil,
            attempt: Execution.Attempt? = nil,
            execution: Execution.Record? = nil,
            metadata: [String: String] = [:]
        ) {
            self.id = id
            self.sessionID = sessionID
            self.invocation = invocation
            self.status = status
            self.expiresAt = expiresAt
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.review = review
            self.attempt = attempt
            self.execution = execution
            self.metadata = metadata
        }
    }

    /// What a run hands over when it defers a call.
    struct Draft: Sendable, Codable, Hashable {
        public var sessionID: String?
        public var invocation: ToolInvocation.Prepared
        public var expiresAt: Date?
        public var metadata: [String: String]

        public init(
            sessionID: String? = nil,
            invocation: ToolInvocation.Prepared,
            expiresAt: Date? = nil,
            metadata: [String: String] = [:]
        ) {
            self.sessionID = sessionID
            self.invocation = invocation
            self.expiresAt = expiresAt
            self.metadata = metadata
        }
    }
}

public extension Intents.Intent {
    /// A non-empty identifier of letters, digits, `-` and `_`. It names the
    /// intent's file, so nothing else is allowed.
    struct ID: CodableInvariant, Sendable, Hashable, Comparable, JSONSchemaProviding, CustomStringConvertible {
        public typealias Error = Intents.Error

        public let raw: String

        public init(
            _ raw: String
        ) throws(Intents.Error) {
            let trimmed = raw.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            guard !trimmed.isEmpty,
                  trimmed.allSatisfy(Self.isAllowed)
            else {
                throw .invalidID(raw)
            }
            self.raw = trimmed
        }

        private init(
            generated raw: String
        ) {
            self.raw = raw
        }

        public static func generate() -> Self {
            .init(
                generated: UUID().uuidString.lowercased()
            )
        }

        public var description: String {
            raw
        }

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.raw < rhs.raw
        }

        public static var jsonschema: JSONSchema {
            .string()
        }

        private static func isAllowed(
            _ character: Character
        ) -> Bool {
            character.isASCII
                && (character.isLetter || character.isNumber || character == "-" || character == "_")
        }
    }

    @JSONSchema
    enum Status: String, Sendable, Codable, Hashable, CaseIterable {
        case pending
        case approved
        case executing
        case denied
        case cancelled
        case expired
        case executed
        case failed
    }

    var operation: PreparedOperation.Envelope {
        invocation.operation
    }

    var tool: ToolIdentifier {
        invocation.review.invocation.tool
    }

    var preflight: ToolPreflight {
        invocation.review.preflight
    }

    func isExpired(
        at date: Date = Date()
    ) -> Bool {
        guard let expiresAt else {
            return false
        }
        return expiresAt <= date
    }
}

public extension Intents.Intent.Status {
    var isTerminal: Bool {
        switch self {
        case .pending, .approved, .executing:
            return false

        case .denied, .cancelled, .expired, .executed, .failed:
            return true
        }
    }

    var canBeReviewed: Bool {
        self == .pending || self == .approved
    }
}
