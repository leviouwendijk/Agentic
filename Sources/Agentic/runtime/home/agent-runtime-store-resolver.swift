import Foundation
import Path

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
        let locations = environment.storageLocations()

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
    func transcriptEventSinks(
        sessionID: String
    ) throws -> [any AgentRunEventSink] {
        guard let transcriptfile = environment.transcriptfile(
            sessionID: sessionID
        ) else {
            return []
        }

        try PathCreation.parent(
            of: transcriptfile
        )

        let store = FileTranscriptStore(
            fileURL: transcriptfile
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
        guard let approvalsfile = environment.approvalsfile(
            sessionID: sessionID
        ) else {
            return nil
        }

        try PathCreation.parent(
            of: approvalsfile
        )

        return FileApprovalEventStore(
            fileURL: approvalsfile
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
}
