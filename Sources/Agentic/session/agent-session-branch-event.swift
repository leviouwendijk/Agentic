import Foundation

public struct AgentSessionBranchEvent: Sendable, Codable, Hashable, Identifiable {
    public let id: String
    public let sessionID: String
    public let branch: AgentSessionBranch
    public let createdAt: Date

    public init(
        id: String = UUID().uuidString,
        sessionID: String,
        branch: AgentSessionBranch,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sessionID = sessionID
        self.branch = branch
        self.createdAt = createdAt
    }

    public var summaryText: String {
        var lines = [
            "session_branch",
            "sessionID=\(sessionID)",
            "parentSessionID=\(branch.parentSessionID)"
        ]

        if let branchedAtEventID = branch.branchedAtEventID {
            lines.append(
                "branchedAtEventID=\(branchedAtEventID)"
            )
        }

        if let branchedAtCheckpointID = branch.branchedAtCheckpointID {
            lines.append(
                "branchedAtCheckpointID=\(branchedAtCheckpointID)"
            )
        }

        if let note = branch.note,
           !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append(
                "note=\(note)"
            )
        }

        return lines.joined(
            separator: "\n"
        )
    }
}
