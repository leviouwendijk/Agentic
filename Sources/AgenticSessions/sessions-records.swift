import Agentic
import Foundation
import Macros
import Schema

public extension Sessions {
    @JSONSchema
    enum Status:
        String,
        Sendable,
        Codable,
        Hashable,
        CaseIterable
    {
        case active
        case awaiting_approval
        case awaiting_user_input
        case completed
        case archived
    }

    @JSONSchema
    struct Metadata:
        Sendable,
        Codable,
        Hashable,
        Identifiable
    {
        public var sessionID: String
        public var createdAt: Date
        public var updatedAt: Date
        public var title: String?
        public var status: Status
        public var profileID: String?
        public var workspaceAttached: Bool
        public var branch: SessionBranch?
        public var metadata: [String: String]

        public init(
            sessionID: String,
            createdAt: Date = Date(),
            updatedAt: Date = Date(),
            title: String? = nil,
            status: Status = .active,
            profileID: String? = nil,
            workspaceAttached: Bool = false,
            branch: SessionBranch? = nil,
            metadata: [String: String] = [:]
        ) {
            self.sessionID = sessionID
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.title = title
            self.status = status
            self.profileID = profileID
            self.workspaceAttached = workspaceAttached
            self.branch = branch
            self.metadata = metadata
        }

        public var id: String {
            sessionID
        }
    }

    @JSONSchema
    struct Summary:
        Sendable,
        Codable,
        Hashable,
        Identifiable
    {
        public let metadata: Metadata
        public let hasCheckpoint: Bool
        public let hasTranscript: Bool
        public let hasApprovals: Bool
        public let artifactCount: Int
        public let intentCount: Int

        public init(
            metadata: Metadata,
            hasCheckpoint: Bool,
            hasTranscript: Bool,
            hasApprovals: Bool,
            artifactCount: Int,
            intentCount: Int = 0
        ) {
            self.metadata = metadata
            self.hasCheckpoint = hasCheckpoint
            self.hasTranscript = hasTranscript
            self.hasApprovals = hasApprovals
            self.artifactCount = artifactCount
            self.intentCount = intentCount
        }

        public var id: String {
            metadata.sessionID
        }
    }

    @JSONSchema
    struct Inspection:
        Sendable,
        Codable,
        Hashable
    {
        public let summary: Summary
        public let transcriptEventCount: Int
        public let approvalEventCount: Int
        public let artifactCount: Int
        public let intentCount: Int
        public let childBranchCount: Int

        public init(
            summary: Summary,
            transcriptEventCount: Int,
            approvalEventCount: Int,
            artifactCount: Int? = nil,
            intentCount: Int? = nil,
            childBranchCount: Int
        ) {
            self.summary = summary
            self.transcriptEventCount = transcriptEventCount
            self.approvalEventCount = approvalEventCount
            self.artifactCount = artifactCount ?? summary.artifactCount
            self.intentCount = intentCount ?? summary.intentCount
            self.childBranchCount = childBranchCount
        }
    }

    /// One approval/audit event of a session.
    @JSONSchema
    struct ApprovalEvent:
        Sendable,
        Codable,
        Hashable,
        Identifiable
    {
        @JSONSchema
        public enum Kind:
            String,
            Sendable,
            Codable,
            Hashable,
            CaseIterable
        {
            case tool_preflight
            case pending_approval
            case approval_decision
        }

        public let id: String
        public let sessionID: String
        public let runEventID: String?
        public let kind: Kind
        public let createdAt: Date
        public let iteration: Int
        public let callID: String?
        public let toolName: String?
        public let decision: ApprovalDecision?
        public let summary: String

        public init(
            id: String = UUID().uuidString,
            sessionID: String,
            runEventID: String? = nil,
            kind: Kind,
            createdAt: Date = Date(),
            iteration: Int,
            callID: String? = nil,
            toolName: String? = nil,
            decision: ApprovalDecision? = nil,
            summary: String
        ) {
            self.id = id
            self.sessionID = sessionID
            self.runEventID = runEventID
            self.kind = kind
            self.createdAt = createdAt
            self.iteration = iteration
            self.callID = callID
            self.toolName = toolName
            self.decision = decision
            self.summary = summary
        }
    }

    /// What one step of a session's durable log records.
    @JSONSchema
    enum LogKind: String, Sendable, Codable, Hashable, CaseIterable {
        case state, observation, request, message, call, response, branch
    }

    /// One step of a session's durable log, without its payloads.
    @JSONSchema
    struct LogLine: HashableResult {
        public let seq: Int
        public let time: Date
        public let run: String?
        public let kind: LogKind
        /// The function call the step is about, if any.
        public let call: String?
        public let summary: String

        public init(
            seq: Int,
            time: Date,
            run: String?,
            kind: LogKind,
            call: String?,
            summary: String
        ) {
            self.seq = seq
            self.time = time
            self.run = run
            self.kind = kind
            self.call = call
            self.summary = summary
        }
    }
}

public extension Sessions.Metadata {
    func touching(
        updatedAt: Date = Date()
    ) -> Self {
        var copy = self
        copy.updatedAt = updatedAt
        return copy
    }

    func withStatus(
        _ status: Sessions.Status,
        updatedAt: Date = Date()
    ) -> Self {
        var copy = self
        copy.status = status
        copy.updatedAt = updatedAt
        return copy
    }

    func withSessionID(
        _ sessionID: String
    ) -> Self {
        var copy = self
        copy.sessionID = sessionID
        return copy
    }
}
