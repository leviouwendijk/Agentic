import Agentic

/// Tool calls stored for review and run later.
///
/// An unattended run that reaches a call needing review stores it as an
/// intent and continues. A person reviews it; approved intents run through
/// the same tool path as an approved live call.
///
/// Tools resolve `Intents.Manager`, `Intents.Executor` and, when the host
/// scopes them to a session, `Intents.Scope` from the invocation's services.
@Domain("intents", aliases: ["intent"])
public enum Intents {}

public extension Intents {
    /// The session intent tools are scoped to. Without one they see every
    /// session's intents.
    struct Scope: Sendable, Hashable {
        public let sessionID: String

        public init(
            sessionID: String
        ) {
            self.sessionID = sessionID
        }
    }
}

extension CapabilityContext {
    func intentManager() throws -> Intents.Manager {
        try require(Intents.Manager.self)
    }

    func intentExecutor() throws -> Intents.Executor {
        try require(Intents.Executor.self)
    }

    func intentSessionID() -> String? {
        (try? require(Intents.Scope.self))?.sessionID
    }
}
