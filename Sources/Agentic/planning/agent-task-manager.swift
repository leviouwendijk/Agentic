import Foundation

public actor AgentTaskManager {
    public let store: any AgentTaskStore

    public init(
        store: any AgentTaskStore
    ) {
        self.store = store
    }

    public static func resolve(
        environment: AgentRuntimeEnvironment
    ) throws -> Self {
        guard let tasksdir = environment.tasksdir() else {
            throw AgentTaskError.durableStorageRequired
        }

        return .init(
            store: FileAgentTaskStore(
                tasksdir: tasksdir
            )
        )
    }

    public func create(
        subject: String,
        description: String = "",
        blockedBy: [AgentTaskIdentifier] = [],
        owner: String? = nil,
        sessionID: String? = nil,
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
        readyOnly: Bool = false,
        includeCompleted: Bool = true
    ) async throws -> [AgentTask] {
        let owner = normalized(
            owner
        )

        return try await store.list().filter { task in
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

        try await store.save(
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
}

private extension AgentTaskManager {
    func clearDependency(
        _ completedID: AgentTaskIdentifier
    ) async throws {
        let tasks = try await store.list()

        for var task in tasks where task.blockedBy.contains(completedID) {
            task.blockedBy.removeAll { id in
                id == completedID
            }

            try await store.save(
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
