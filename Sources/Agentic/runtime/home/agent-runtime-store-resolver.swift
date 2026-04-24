import Foundation

public struct AgentRuntimeStoreResolver: Sendable {
    public let environment: AgentRuntimeEnvironment

    public init(
        environment: AgentRuntimeEnvironment
    ) {
        self.environment = environment
    }

    public func resolveStores(
        sessionID: String
    ) throws -> AgentRuntimeStores {
        let locations = storageLocations()

        guard environment.sessionStorageMode.isDurable else {
            return .init()
        }

        try environment.createSessionDirectories(
            sessionID: sessionID
        )

        let historyStore = locations.sessionsdir.map {
            FileHistoryStore(
                sessionsdir: $0
            ) as any AgentHistoryStore
        }

        let sessionMetadataStore = locations.sessionsdir.map {
            FileSessionMetadataStore(
                sessionsdir: $0
            ) as any AgentSessionMetadataStore
        }

        let approvalEventStore = try approvalEventStore(
            sessionID: sessionID
        )

        let eventSinks =
            try transcriptEventSinks(
                sessionID: sessionID
            )
            + approvalEventSinks(
                sessionID: sessionID,
                approvalEventStore: approvalEventStore
            )

        return .init(
            historyStore: historyStore,
            sessionMetadataStore: sessionMetadataStore,
            approvalEventStore: approvalEventStore,
            eventSinks: eventSinks,
            sessionsdir: locations.sessionsdir,
            transcriptsdir: locations.transcriptsdir,
            approvalsdir: locations.approvalsdir,
            artifactsdir: locations.artifactsdir
        )
    }
}

private extension AgentRuntimeStoreResolver {
    struct StorageLocations: Sendable {
        let sessionsdir: URL?
        let transcriptsdir: URL?
        let approvalsdir: URL?
        let artifactsdir: URL?
    }

    func transcriptEventSinks(
        sessionID: String
    ) throws -> [any AgentRunEventSink] {
        guard let transcriptFileURL = environment.transcriptFileURL(
            sessionID: sessionID
        ) else {
            return []
        }

        try FileManager.default.createDirectory(
            at: transcriptFileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )

        let store = FileTranscriptStore(
            fileURL: transcriptFileURL
        )

        return [
            AgentTranscriptRecorder(
                store: store
            )
        ]
    }

    func approvalEventStore(
        sessionID: String
    ) throws -> (any AgentApprovalEventStore)? {
        guard let approvalFileURL = environment.approvalsFileURL(
            sessionID: sessionID
        ) else {
            return nil
        }

        try FileManager.default.createDirectory(
            at: approvalFileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )

        return FileApprovalEventStore(
            fileURL: approvalFileURL
        )
    }

    func approvalEventSinks(
        sessionID: String,
        approvalEventStore: (any AgentApprovalEventStore)?
    ) -> [any AgentRunEventSink] {
        guard let approvalEventStore else {
            return []
        }

        return [
            AgentApprovalRecorder(
                sessionID: sessionID,
                store: approvalEventStore
            )
        ]
    }

    func storageLocations() -> StorageLocations {
        switch environment.sessionStorageMode {
        case .global_home:
            return .init(
                sessionsdir: environment.home.layout.sessionsdir,
                transcriptsdir: environment.home.layout.transcriptsdir,
                approvalsdir: environment.home.layout.approvalsdir,
                artifactsdir: environment.home.layout.artifactsdir
            )

        case .project_local:
            return .init(
                sessionsdir: environment.projectDiscovery?.agenticdir
                    .appendingPathComponent(
                        "sessions",
                        isDirectory: true
                    ),
                transcriptsdir: environment.projectDiscovery?.agenticdir
                    .appendingPathComponent(
                        "transcripts",
                        isDirectory: true
                    ),
                approvalsdir: environment.projectDiscovery?.agenticdir
                    .appendingPathComponent(
                        "approvals",
                        isDirectory: true
                    ),
                artifactsdir: environment.projectDiscovery?.agenticdir
                    .appendingPathComponent(
                        "artifacts",
                        isDirectory: true
                    )
            )

        case .custom(let root):
            return .init(
                sessionsdir: root.appendingPathComponent(
                    "sessions",
                    isDirectory: true
                ),
                transcriptsdir: root.appendingPathComponent(
                    "transcripts",
                    isDirectory: true
                ),
                approvalsdir: root.appendingPathComponent(
                    "approvals",
                    isDirectory: true
                ),
                artifactsdir: root.appendingPathComponent(
                    "artifacts",
                    isDirectory: true
                )
            )

        case .ephemeral:
            return .init(
                sessionsdir: nil,
                transcriptsdir: nil,
                approvalsdir: nil,
                artifactsdir: nil
            )
        }
    }
}
