public struct AgentSessionBranch: Sendable, Codable, Hashable {
    public let parentSessionID: String
    public let branchedAtEventID: String?
    public let branchedAtCheckpointID: String?
    public let note: String?

    public init(
        parentSessionID: String,
        branchedAtEventID: String? = nil,
        branchedAtCheckpointID: String? = nil,
        note: String? = nil
    ) {
        self.parentSessionID = parentSessionID
        self.branchedAtEventID = branchedAtEventID
        self.branchedAtCheckpointID = branchedAtCheckpointID
        self.note = note
    }
}
