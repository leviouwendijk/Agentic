import Foundation

public struct AgentHomeLayout: Sendable, Codable, Hashable {
    public let root: URL

    public init(
        root: URL
    ) {
        self.root = root.standardizedFileURL
    }

    public var configfile: URL {
        root.appendingPathComponent(
            "config.json",
            isDirectory: false
        )
    }

    public var profilesdir: URL {
        root.appendingPathComponent(
            "profiles",
            isDirectory: true
        )
    }

    public var sessionsdir: URL {
        root.appendingPathComponent(
            "sessions",
            isDirectory: true
        )
    }

    public var transcriptsdir: URL {
        root.appendingPathComponent(
            "transcripts",
            isDirectory: true
        )
    }

    public var approvalsdir: URL {
        root.appendingPathComponent(
            "approvals",
            isDirectory: true
        )
    }

    public var tasksdir: URL {
        root.appendingPathComponent(
            "tasks",
            isDirectory: true
        )
    }

    public var artifactsdir: URL {
        root.appendingPathComponent(
            "artifacts",
            isDirectory: true
        )
    }

    public var cachedir: URL {
        root.appendingPathComponent(
            "cache",
            isDirectory: true
        )
    }

    public var tmpdir: URL {
        root.appendingPathComponent(
            "tmp",
            isDirectory: true
        )
    }

    public func sessiondir(
        sessionID: String
    ) -> URL {
        sessionsdir.appendingPathComponent(
            sessionID,
            isDirectory: true
        )
    }

    public func checkpointFileURL(
        sessionID: String
    ) -> URL {
        sessiondir(
            sessionID: sessionID
        )
        .appendingPathComponent(
            "checkpoint.json",
            isDirectory: false
        )
    }

    public func sessionStateFileURL(
        sessionID: String
    ) -> URL {
        sessiondir(
            sessionID: sessionID
        )
        .appendingPathComponent(
            "state.json",
            isDirectory: false
        )
    }

    public func transcriptFileURL(
        sessionID: String
    ) -> URL {
        transcriptsdir.appendingPathComponent(
            "\(sessionID).jsonl",
            isDirectory: false
        )
    }

    public func approvalsFileURL(
        sessionID: String
    ) -> URL {
        approvalsdir.appendingPathComponent(
            "\(sessionID).jsonl",
            isDirectory: false
        )
    }

    public func artifactdir(
        sessionID: String
    ) -> URL {
        artifactsdir.appendingPathComponent(
            sessionID,
            isDirectory: true
        )
    }

    public func createBaseDirectories() throws {
        try createDirectories(
            [
                root,
                profilesdir,
                sessionsdir,
                transcriptsdir,
                approvalsdir,
                tasksdir,
                artifactsdir,
                cachedir,
                tmpdir
            ]
        )
    }

    public func createSessionDirectories(
        sessionID: String
    ) throws {
        try createDirectories(
            [
                sessiondir(
                    sessionID: sessionID
                ),
                transcriptsdir,
                approvalsdir,
                artifactdir(
                    sessionID: sessionID
                )
            ]
        )
    }
}

private extension AgentHomeLayout {
    func createDirectories(
        _ urls: [URL]
    ) throws {
        for url in urls {
            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
}
