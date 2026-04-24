import Foundation

public struct AgentRuntimeStores: Sendable {
    public let historyStore: (any AgentHistoryStore)?
    public let sessionMetadataStore: (any AgentSessionMetadataStore)?
    public let approvalEventStore: (any AgentApprovalEventStore)?
    public let eventSinks: [any AgentRunEventSink]
    public let sessionsdir: URL?
    public let transcriptsdir: URL?
    public let approvalsdir: URL?
    public let artifactsdir: URL?

    public init(
        historyStore: (any AgentHistoryStore)? = nil,
        sessionMetadataStore: (any AgentSessionMetadataStore)? = nil,
        approvalEventStore: (any AgentApprovalEventStore)? = nil,
        eventSinks: [any AgentRunEventSink] = [],
        sessionsdir: URL? = nil,
        transcriptsdir: URL? = nil,
        approvalsdir: URL? = nil,
        artifactsdir: URL? = nil
    ) {
        self.historyStore = historyStore
        self.sessionMetadataStore = sessionMetadataStore
        self.approvalEventStore = approvalEventStore
        self.eventSinks = eventSinks
        self.sessionsdir = sessionsdir
        self.transcriptsdir = transcriptsdir
        self.approvalsdir = approvalsdir
        self.artifactsdir = artifactsdir
    }
}
