import Foundation

public actor FileAgentTaskStore: AgentTaskStore {
    public let tasksdir: URL

    public init(
        tasksdir: URL
    ) {
        self.tasksdir = tasksdir.standardizedFileURL
    }

    public func load(
        id: AgentTaskIdentifier
    ) async throws -> AgentTask? {
        let url = taskFileURL(
            id: id
        )

        guard FileManager.default.fileExists(
            atPath: url.path
        ) else {
            return nil
        }

        let data = try Data(
            contentsOf: url
        )

        guard !data.isEmpty else {
            return nil
        }

        return try JSONDecoder().decode(
            AgentTask.self,
            from: data
        )
    }

    public func list() async throws -> [AgentTask] {
        guard FileManager.default.fileExists(
            atPath: tasksdir.path
        ) else {
            return []
        }

        let urls = try FileManager.default.contentsOfDirectory(
            at: tasksdir,
            includingPropertiesForKeys: nil,
            options: [
                .skipsHiddenFiles
            ]
        )

        let tasks = try urls.compactMap { url -> AgentTask? in
            guard url.pathExtension == "json" else {
                return nil
            }

            let data = try Data(
                contentsOf: url
            )

            guard !data.isEmpty else {
                return nil
            }

            return try JSONDecoder().decode(
                AgentTask.self,
                from: data
            )
        }

        return tasks.sorted { lhs, rhs in
            if lhs.status == rhs.status {
                return lhs.updatedAt > rhs.updatedAt
            }

            return lhs.status.rawValue < rhs.status.rawValue
        }
    }

    public func save(
        _ task: AgentTask
    ) async throws {
        try FileManager.default.createDirectory(
            at: tasksdir,
            withIntermediateDirectories: true,
            attributes: nil
        )

        var task = task
        task.updatedAt = Date()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys
        ]

        let data = try encoder.encode(
            task
        )

        try data.write(
            to: taskFileURL(
                id: task.id
            ),
            options: .atomic
        )
    }

    public func delete(
        id: AgentTaskIdentifier
    ) async throws {
        let url = taskFileURL(
            id: id
        )

        guard FileManager.default.fileExists(
            atPath: url.path
        ) else {
            return
        }

        try FileManager.default.removeItem(
            at: url
        )
    }
}

private extension FileAgentTaskStore {
    func taskFileURL(
        id: AgentTaskIdentifier
    ) -> URL {
        tasksdir.appendingPathComponent(
            "task-\(safeFileComponent(id.rawValue)).json",
            isDirectory: false
        )
    }

    func safeFileComponent(
        _ value: String
    ) -> String {
        value.map { character in
            if character.isLetter || character.isNumber || character == "-" || character == "_" {
                return character
            }

            return "_"
        }.map(String.init).joined()
    }
}
