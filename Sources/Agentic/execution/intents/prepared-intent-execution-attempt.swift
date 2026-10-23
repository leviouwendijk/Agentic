import Foundation
import Macros
import Schema

/// Durable evidence of an exclusive claim, written before invoking effects.
/// A surviving executing attempt after interruption is unresolved, not retryable.
@JSONSchema
public struct PreparedIntentExecutionAttempt: Sendable, Codable, Hashable, Identifiable {
    public let id: String
    public let startedAt: Date
    public let operation: PreparedOperation.Schema

    public init(
        id: String = UUID().uuidString,
        startedAt: Date = Date(),
        operation: PreparedOperation.Schema
    ) {
        self.id = id
        self.startedAt = startedAt
        self.operation = operation
    }
}
