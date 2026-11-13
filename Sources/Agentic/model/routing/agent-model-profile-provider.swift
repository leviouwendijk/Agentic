public protocol AgentModelProfileProvider: Sendable {
    func profiles() throws -> [AgentModelProfile]
}
