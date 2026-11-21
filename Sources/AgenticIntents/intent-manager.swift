import Agentic
import Foundation

public extension Intents {
    /// The intent lifecycle: pending → approved → executing → executed or
    /// failed, with denied, cancelled and expired as other ends. Every
    /// transition replaces exactly the intent it read, so concurrent
    /// reviewers and executors cannot both win.
    actor Manager {
        public let store: any Store

        public init(
            store: any Store
        ) {
            self.store = store
        }

        public func create(
            _ draft: Draft
        ) async throws -> Intent {
            let intent = Intent(
                sessionID: normalized(draft.sessionID),
                invocation: draft.invocation,
                expiresAt: draft.expiresAt,
                metadata: draft.metadata
            )
            guard try await store.insert(intent) else {
                throw Error.alreadyExists(intent.id)
            }
            return intent
        }

        public func intent(
            _ id: Intent.ID
        ) async throws -> Intent {
            guard let intent = try await store.load(id) else {
                throw Error.notFound(id)
            }
            return intent
        }

        public func list(
            statuses: [Intent.Status] = [],
            sessionID: String? = nil,
            tool: ToolIdentifier? = nil,
            includeExpired: Bool = false
        ) async throws -> [Intent] {
            let sessionID = normalized(sessionID)
            let now = Date()

            return try await store.list().filter { intent in
                if !includeExpired,
                   intent.status != .expired,
                   !intent.status.isTerminal,
                   intent.isExpired(at: now) {
                    return false
                }
                if !statuses.isEmpty,
                   !statuses.contains(intent.status) {
                    return false
                }
                if let sessionID,
                   intent.sessionID != sessionID {
                    return false
                }
                if let tool,
                   intent.tool != tool {
                    return false
                }
                return true
            }
        }

        /// Records a person's decision. Approving an expired intent expires
        /// it instead and throws.
        public func review(
            _ id: Intent.ID,
            decision: Review.Decision,
            reviewer: String? = nil,
            note: String? = nil
        ) async throws -> Intent {
            let original = try await intent(id)
            guard original.status.canBeReviewed else {
                throw Error.notReviewable(id, original.status)
            }

            let now = Date()
            let expired = decision == .approve && original.isExpired(at: now)
            var intent = original
            intent.status = expired ? .expired : decision.status
            intent.updatedAt = now
            intent.review = .init(
                decision: expired ? .expire : decision,
                reviewer: normalized(reviewer),
                note: normalized(note),
                at: now
            )

            guard try await store.replace(intent, matching: original) else {
                throw Error.concurrentModification(id)
            }
            if expired {
                throw Error.expired(id)
            }
            return intent
        }

        /// Claims an approved intent for one execution: it moves to
        /// `executing` with a fresh attempt, so no other executor can run it.
        public func claim(
            _ id: Intent.ID,
            at now: Date = Date()
        ) async throws -> Intent {
            let original = try await intent(id)

            if original.isExpired(at: now),
               !original.status.isTerminal,
               original.status != .executing {
                var expired = original
                expired.status = .expired
                expired.updatedAt = now
                guard try await store.replace(expired, matching: original) else {
                    throw Error.concurrentModification(id)
                }
                throw Error.expired(id)
            }

            guard original.status == .approved else {
                throw Error.notApproved(id, original.status)
            }

            var intent = original
            intent.status = .executing
            intent.updatedAt = now
            intent.attempt = .init(startedAt: now)

            guard try await store.replace(intent, matching: original) else {
                throw Error.concurrentModification(id)
            }
            return intent
        }

        /// Ends the claimed attempt with its record.
        public func finish(
            _ id: Intent.ID,
            with record: Execution.Record
        ) async throws -> Intent {
            let original = try await intent(id)
            guard original.status == .executing,
                  original.attempt?.id == record.attemptID
            else {
                throw Error.attemptMismatch(
                    id,
                    expected: original.attempt?.id,
                    actual: record.attemptID
                )
            }

            var intent = original
            intent.status = record.outcome.status
            intent.updatedAt = record.completedAt
            intent.execution = record

            guard try await store.replace(intent, matching: original) else {
                throw Error.concurrentModification(id)
            }
            return intent
        }

        public func delete(
            _ id: Intent.ID
        ) async throws {
            try await store.delete(id)
        }
    }
}

private extension Intents.Manager {
    func normalized(
        _ value: String?
    ) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty
        else {
            return nil
        }
        return trimmed
    }
}
