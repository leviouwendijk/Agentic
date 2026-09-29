import Foundation

public actor FileTranscriptStore: TranscriptStore {
    public let fileURL: URL

    public init(
        fileURL: URL
    ) {
        self.fileURL = fileURL
    }

    public func loadEvents() async throws -> [TranscriptEvent] {
        guard FileManager.default.fileExists(
            atPath: fileURL.path
        ) else {
            return []
        }

        let data = try Data(
            contentsOf: fileURL
        )

        guard !data.isEmpty else {
            return []
        }

        if let events = try? JSONDecoder().decode(
            [TranscriptEvent].self,
            from: data
        ) {
            return events
        }

        guard let text = String(
            data: data,
            encoding: .utf8
        ) else {
            return []
        }

        return try text
            .split(
                separator: "\n",
                omittingEmptySubsequences: true
            )
            .map { line in
                let data = Data(line.utf8)

                return try JSONDecoder().decode(
                    TranscriptEvent.self,
                    from: data
                )
            }
    }

    public func append(
        _ event: TranscriptEvent
    ) async throws {
        try ensureParentDirectoryExists()

        let data = try JSONEncoder().encode(
            event
        )

        if !FileManager.default.fileExists(
            atPath: fileURL.path
        ) {
            try data.write(
                to: fileURL,
                options: .atomic
            )
            try appendNewline()
            return
        }

        let handle = try FileHandle(
            forWritingTo: fileURL
        )

        defer {
            try? handle.close()
        }

        try handle.seekToEnd()

        if try needsLeadingNewline() {
            try handle.write(
                contentsOf: Data("\n".utf8)
            )
        }

        try handle.write(
            contentsOf: data
        )
        try handle.write(
            contentsOf: Data("\n".utf8)
        )
    }
}

private extension FileTranscriptStore {
    func ensureParentDirectoryExists() throws {
        let directoryURL = fileURL.deletingLastPathComponent()

        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }

    func appendNewline() throws {
        let handle = try FileHandle(
            forWritingTo: fileURL
        )

        defer {
            try? handle.close()
        }

        try handle.seekToEnd()
        try handle.write(
            contentsOf: Data("\n".utf8)
        )
    }

    func needsLeadingNewline() throws -> Bool {
        let handle = try FileHandle(
            forReadingFrom: fileURL
        )

        defer {
            try? handle.close()
        }

        let length = try handle.seekToEnd()

        guard length > 0 else {
            return false
        }

        try handle.seek(
            toOffset: length - 1
        )

        let data = handle.readDataToEndOfFile()

        guard let lastByte = data.first else {
            return false
        }

        return lastByte != Character("\n").asciiValue
    }
}
