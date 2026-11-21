import Agentic
import Foundation
import Macros
import Primitives
import Schema

public extension Intents {
    enum Execution {}
}

public extension Intents.Execution {
    /// The claim on an intent, written before its call runs.
    @JSONSchema
    struct Attempt: Sendable, Codable, Hashable, Identifiable {
        public let id: String
        public let startedAt: Date

        public init(
            id: String = UUID().uuidString.lowercased(),
            startedAt: Date = Date()
        ) {
            self.id = id
            self.startedAt = startedAt
        }
    }

    @JSONSchema
    enum Outcome: String, Sendable, Codable, Hashable, CaseIterable {
        case succeeded
        case failed
    }

    /// How an attempt ended.
    @JSONSchema
    struct Record: Sendable, Codable, Hashable {
        public let attemptID: String
        public let outcome: Outcome
        public let summary: String
        public let startedAt: Date
        public let completedAt: Date
        /// The tool's output, as the model would have seen it.
        public let output: JSONValue?
        public let error: String?

        public init(
            attemptID: String,
            outcome: Outcome,
            summary: String,
            startedAt: Date,
            completedAt: Date = Date(),
            output: JSONValue? = nil,
            error: String? = nil
        ) {
            self.attemptID = attemptID
            self.outcome = outcome
            self.summary = summary
            self.startedAt = startedAt
            self.completedAt = completedAt
            self.output = output
            self.error = error
        }
    }
}

public extension Intents.Execution.Outcome {
    var status: Intents.Intent.Status {
        switch self {
        case .succeeded:
            return .executed

        case .failed:
            return .failed
        }
    }
}
