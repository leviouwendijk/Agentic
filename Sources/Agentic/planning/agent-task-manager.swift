import Foundation

public actor AgentTaskManager {
    public let store: any AgentTaskStore

    public init(
        store: any AgentTaskStore
    ) {
        self.store = store
    }

    public func create(
        subject: String,
        description: String = "",
        blockedBy: [AgentTaskIdentifier] = [],
        owner: String? = nil,
        sessionID: String? = nil,
        contract: AgentTaskContract? = nil,
        metadata: [String: String] = [:]
    ) async throws -> AgentTask {
        let subject = subject.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !subject.isEmpty else {
            throw AgentTaskError.emptySubject
        }

        let task = AgentTask(
            subject: subject,
            description: description,
            owner: normalized(
                owner
            ),
            blockedBy: uniqueSorted(
                blockedBy
            ),
            sessionID: normalized(
                sessionID
            ),
            contract: contract,
            metadata: metadata
        )

        try await store.save(
            task
        )

        return task
    }

    public func get(
        _ id: AgentTaskIdentifier
    ) async throws -> AgentTask {
        guard let task = try await store.load(
            id: id
        ) else {
            throw AgentTaskError.taskNotFound(
                id
            )
        }

        return task
    }

    public func list(
        statuses: [AgentTaskStatus] = [],
        owner: String? = nil,
        sessionID: String? = nil,
        readyOnly: Bool = false,
        includeCompleted: Bool = true
    ) async throws -> [AgentTask] {
        let owner = normalized(
            owner
        )
        let sessionID = normalized(
            sessionID
        )

        return try await store.list().filter { task in
            if let sessionID,
               task.sessionID != sessionID {
                return false
            }

            if !includeCompleted,
               task.status == .completed {
                return false
            }

            if !statuses.isEmpty,
               !statuses.contains(task.status) {
                return false
            }

            if let owner,
               task.owner != owner {
                return false
            }

            if readyOnly,
               !task.isReady {
                return false
            }

            return true
        }
    }

    public func update(
        id: AgentTaskIdentifier,
        subject: String? = nil,
        description: String? = nil,
        status: AgentTaskStatus? = nil,
        owner: String? = nil,
        addBlockedBy: [AgentTaskIdentifier] = [],
        removeBlockedBy: [AgentTaskIdentifier] = [],
        sessionID: String? = nil,
        metadataPatch: [String: String] = [:]
    ) async throws -> AgentTask {
        var task = try await get(
            id
        )

        if let subject {
            let trimmed = subject.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard !trimmed.isEmpty else {
                throw AgentTaskError.emptySubject
            }

            task.subject = trimmed
        }

        if let description {
            task.description = description
        }

        if let status {
            task.status = status
        }

        if let owner {
            task.owner = normalized(
                owner
            )
        }

        if let sessionID {
            task.sessionID = normalized(
                sessionID
            )
        }

        if !addBlockedBy.isEmpty {
            task.blockedBy = uniqueSorted(
                task.blockedBy + addBlockedBy
            )
        }

        if !removeBlockedBy.isEmpty {
            let removals = Set(
                removeBlockedBy
            )

            task.blockedBy.removeAll { id in
                removals.contains(
                    id
                )
            }
        }

        if !metadataPatch.isEmpty {
            task.metadata.merge(
                metadataPatch,
                uniquingKeysWith: { _, new in
                    new
                }
            )
        }

        try await save(
            task
        )

        if status == .completed {
            try await clearDependency(
                id
            )
        }

        return try await get(
            id
        )
    }

    public func claim(
        id: AgentTaskIdentifier,
        owner: String
    ) async throws -> AgentTask {
        try await update(
            id: id,
            status: .processing,
            owner: owner
        )
    }

    public func complete(
        id: AgentTaskIdentifier
    ) async throws -> AgentTask {
        try await update(
            id: id,
            status: .completed
        )
    }

    public func delete(
        id: AgentTaskIdentifier
    ) async throws {
        try await store.delete(
            id: id
        )
    }

    /// Record an assignee's report. The task waits for a coordinator's
    /// acceptance; the report alone never completes it.
    public func recordAttempt(
        id: AgentTaskIdentifier,
        owner: String? = nil,
        report: AgentTaskAttemptReport
    ) async throws -> AgentTask {
        var task = try await get(
            id
        )

        switch task.status {
        case .pending, .processing:
            break

        default:
            throw AgentTaskError.invalidTransition(
                id,
                from: task.status,
                to: .awaiting_acceptance
            )
        }

        task.attempts.append(
            .init(
                number: task.attempts.count + 1,
                owner: normalized(owner) ?? task.owner,
                report: report
            )
        )
        task.status = .awaiting_acceptance

        try await save(
            task
        )

        return task
    }

    /// Accept the submitted attempt, complete the task, and unblock dependents.
    public func accept(
        id: AgentTaskIdentifier,
        note: String? = nil
    ) async throws -> AgentTask {
        try await decide(
            id: id,
            outcome: .accepted,
            status: .completed,
            note: note
        )
    }

    /// Return the task to `pending` for a bounded retry. The note travels
    /// with the rejected attempt as the next attempt's starting evidence.
    public func reject(
        id: AgentTaskIdentifier,
        note: String
    ) async throws -> AgentTask {
        try await decide(
            id: id,
            outcome: .rejected,
            status: .pending,
            note: note
        )
    }

    public func fail(
        id: AgentTaskIdentifier,
        note: String
    ) async throws -> AgentTask {
        try await decide(
            id: id,
            outcome: .failed,
            status: .failed,
            note: note
        )
    }
}

private extension AgentTaskManager {
    func decide(
        id: AgentTaskIdentifier,
        outcome: AgentTaskAttemptOutcome,
        status: AgentTaskStatus,
        note: String?
    ) async throws -> AgentTask {
        var task = try await get(
            id
        )

        guard task.status == .awaiting_acceptance,
              let index = task.attempts.indices.last,
              task.attempts[index].outcome == .submitted
        else {
            throw AgentTaskError.noSubmittedAttempt(
                id
            )
        }

        task.attempts[index].outcome = outcome
        task.attempts[index].decisionNote = normalized(
            note
        )
        task.attempts[index].decidedAt = Date()
        task.status = status

        try await save(
            task
        )

        if status == .completed {
            try await clearDependency(
                id
            )
        }

        return task
    }

    func save(
        _ task: AgentTask
    ) async throws {
        var task = task
        task.updatedAt = Date()

        try await store.save(
            task
        )
    }

    func clearDependency(
        _ completedID: AgentTaskIdentifier
    ) async throws {
        let tasks = try await store.list()

        for var task in tasks where task.blockedBy.contains(completedID) {
            task.blockedBy.removeAll { id in
                id == completedID
            }

            try await save(
                task
            )
        }
    }

    func normalized(
        _ value: String?
    ) -> String? {
        guard let value else {
            return nil
        }

        let trimmed = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return trimmed.isEmpty ? nil : trimmed
    }

    func uniqueSorted(
        _ values: [AgentTaskIdentifier]
    ) -> [AgentTaskIdentifier] {
        Array(
            Set(values)
        ).sorted { lhs, rhs in
            lhs.rawValue < rhs.rawValue
        }
    }
}
