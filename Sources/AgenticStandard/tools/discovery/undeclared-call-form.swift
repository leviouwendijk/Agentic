import Agentic

/// How the model serving the run reaches a capability outside its tool
/// definitions: by its own name where the route takes such calls
/// (`AgentModelCapability.undeclared_calls`), else through
/// `call_capability`. The runtime provides it from the route of the last
/// response; without it, the dispatcher.
public struct UndeclaredCallForm: Sendable {
    public let byName: Bool

    public init(byName: Bool) {
        self.byName = byName
    }
}
