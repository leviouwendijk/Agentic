/// Owner-granted: makes available capabilities visible from the next model
/// turn. It never grants availability; capabilities outside the available
/// set are ignored. The runtime installs it as a tool service.
public struct CapabilityReveal: Sendable {
    private let reveal: @Sendable (AgentCapabilitySet) async -> AgentCapabilitySet

    public init(
        _ reveal: @escaping @Sendable (AgentCapabilitySet) async -> AgentCapabilitySet
    ) {
        self.reveal = reveal
    }

    /// The capabilities that became visible.
    @discardableResult
    public func callAsFunction(
        _ capabilities: AgentCapabilitySet
    ) async -> AgentCapabilitySet {
        await reveal(capabilities)
    }
}

public extension CapabilityReveal {
    /// Reveals within this state's available set.
    init(_ state: AgentCapabilityState) {
        self.init { capabilities in
            await state.reveal(capabilities)
        }
    }
}
