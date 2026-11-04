/// Read-only capability-state interface for execution-facing consumers.
///
/// A Tool may inspect the Agent's installed, available and visible
/// capabilities but receives no mutation operations through this contract.
/// The trusted Host and Runtime retain the concrete AgentCapabilityState
/// for authorized installation, availability and visibility changes.
///
/// This is an API authority boundary, not an isolation mechanism for
/// arbitrary untrusted Swift code executing inside the Host process.
public protocol AgentCapabilityObserving: AnyObject, Sendable {
    func snapshot() async -> AgentCapabilityState.Snapshot
}

extension AgentCapabilityState: AgentCapabilityObserving {}
