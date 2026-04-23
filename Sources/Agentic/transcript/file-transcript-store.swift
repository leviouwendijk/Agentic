import Foundation

public actor FileTranscriptStore: AgentTranscriptStore {
    public let fileURL: URL

    public init(
        fileURL: URL
    ) {
        self.fileURL = fileURL
    }

    public func loadEvents() async throws -> [AgentTranscriptEvent] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)

        guard !data.isEmpty else {
            return []
        }

        return try JSONDecoder().decode([AgentTranscriptEvent].self, from: data)
    }

    public func append(
        _ event: AgentTranscriptEvent
    ) async throws {
        var events = try await loadEvents()
        events.append(event)

        let data = try JSONEncoder().encode(events)
        try data.write(to: fileURL, options: .atomic)
    }
}
