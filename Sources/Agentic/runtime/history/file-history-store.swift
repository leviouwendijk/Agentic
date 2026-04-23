import Foundation

public actor FileHistoryStore: AgentHistoryStore {
    public let directoryURL: URL

    public init(
        directoryURL: URL
    ) {
        self.directoryURL = directoryURL
    }

    public func loadCheckpoint(
        sessionID: String
    ) async throws -> AgentHistoryCheckpoint? {
        let url = checkpointURL(
            for: sessionID
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
            AgentHistoryCheckpoint.self,
            from: data
        )
    }

    public func saveCheckpoint(
        _ checkpoint: AgentHistoryCheckpoint
    ) async throws {
        try ensureDirectoryExists()

        let url = checkpointURL(
            for: checkpoint.id
        )
        let data = try JSONEncoder().encode(
            checkpoint
        )

        try data.write(
            to: url,
            options: .atomic
        )
    }

    public func deleteCheckpoint(
        sessionID: String
    ) async throws {
        let url = checkpointURL(
            for: sessionID
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

private extension FileHistoryStore {
    func checkpointURL(
        for sessionID: String
    ) -> URL {
        directoryURL.appendingPathComponent(
            "\(sessionID).json"
        )
    }

    func ensureDirectoryExists() throws {
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }
}
