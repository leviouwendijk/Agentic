import Agentic

/// Durable task graph tools. Tools resolve `AgentTaskManager` and, when the
/// host supplies one, `AgentTaskScope` from trusted session services.
@Domain
public enum Tasks {}

extension ToolContext {
    func taskManager() throws -> AgentTaskManager {
        try require(AgentTaskManager.self)
    }

    /// The current session, when the host scoped task tools to one.
    func taskSessionID() -> String? {
        (try? require(AgentTaskScope.self))?.sessionID
    }
}
