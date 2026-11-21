import Agentic
import Primitives

public extension Sessions {
    /// Durable sessions: their metadata, transcripts, approvals and
    /// artifacts. A runtime provides one; the session tools read it.
    protocol CatalogReading: Sendable {
        func sessions(statuses: [Status], includeArchived: Bool) async throws -> [Summary]
        func branches(parentSessionID: String) async throws -> [Summary]
        func session(id: String) async throws -> Summary
        func inspection(sessionID: String) async throws -> Inspection
        func transcript(sessionID: String) async throws -> [TranscriptEvent]
        func approvals(sessionID: String) async throws -> [ApprovalEvent]
        func artifacts(sessionID: String, kinds: [AgentArtifactKind], latestFirst: Bool) async throws -> [AgentArtifact]
        func artifact(sessionID: String, id: String) async throws -> AgentArtifactRecord
    }

    /// One session's durable log, step by step.
    protocol LogReading: Sendable {
        /// The session the log belongs to, and every step in order.
        func lines() async throws -> (session: String, lines: [LogLine])
        /// One step with its stored bodies filled in; nil when absent.
        func step(seq: Int) async throws -> (line: LogLine, detail: JSONValue)?
        /// A stored body by its digest.
        func payload(digest: String) async throws -> JSONValue
    }

    /// Every session's canonical message history, including what
    /// compaction took out of later requests. Hosts feed it as runs settle
    /// and install it as a service for `sessions_tool_read_history`.
    actor HistoryStore {
        private var messagesBySessionID: [String: [Message]]

        public init() {
            self.messagesBySessionID = [:]
        }

        public func record(
            _ messages: [Message],
            sessionID: String
        ) {
            messagesBySessionID[sessionID] = messages
        }

        public func messages(
            sessionID: String
        ) -> [Message]? {
            messagesBySessionID[sessionID]
        }

        public func sessionIDs() -> [String] {
            messagesBySessionID.keys.sorted()
        }
    }
}
