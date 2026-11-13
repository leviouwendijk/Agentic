/// Mutable live capability state for one realized Agent.
///
/// Every mutation preserves:
///
/// visible ⊆ available ⊆ installed
///
/// The state is capability-generic. Capability-specific execution paths may
/// project one member set at their boundary without redefining Agent authority.
public actor AgentCapabilityState {
    public struct Snapshot:
        Sendable,
        Codable,
        Hashable
    {
        public let installed: AgentCapabilitySet
        public let available: AgentCapabilitySet
        public let visible: AgentCapabilitySet

        public init(
            installed: AgentCapabilitySet,
            available: AgentCapabilitySet,
            visible: AgentCapabilitySet
        ) {
            self.installed = installed
            self.available = available
            self.visible = visible
        }
    }

    private var installedCapabilities:
        AgentCapabilitySet
    private var availableCapabilities:
        AgentCapabilitySet
    private var visibleCapabilities:
        AgentCapabilitySet
    private var hasLiveMutations = false

    public init(
        installed: AgentCapabilitySet,
        available: AgentCapabilitySet? = nil,
        visible: AgentCapabilitySet? = nil
    ) {
        let available = (
            available
            ?? installed
        ).intersecting(
            installed
        )
        let visible = (
            visible
            ?? available
        ).intersecting(
            available
        )

        self.installedCapabilities = installed
        self.availableCapabilities = available
        self.visibleCapabilities = visible
    }

    public var installed: AgentCapabilitySet {
        installedCapabilities
    }

    public var available: AgentCapabilitySet {
        availableCapabilities
    }

    public var visible: AgentCapabilitySet {
        visibleCapabilities
    }

    public func snapshot() -> Snapshot {
        .init(
            installed: installedCapabilities,
            available: availableCapabilities,
            visible: visibleCapabilities
        )
    }

    @discardableResult
    public func restore(
        _ snapshot: Snapshot,
        overwritingLiveChanges: Bool = false
    ) -> Snapshot {
        if hasLiveMutations && !overwritingLiveChanges {
            return self.snapshot()
        }
        availableCapabilities =
            snapshot.available.intersecting(
                installedCapabilities
            )
        visibleCapabilities =
            snapshot.visible.intersecting(
                availableCapabilities
            )
        hasLiveMutations = true

        return self.snapshot()
    }

    /// Installation grows this Agent's executable universe. It does not enable
    /// or expose the newly installed capabilities.
    @discardableResult
    public func install(
        _ capabilities: AgentCapabilitySet
    ) -> Snapshot {
        installedCapabilities = installedCapabilities.union(capabilities)
        hasLiveMutations = true
        return snapshot()
    }

    /// Strict enablement: a missing implementation is a programming/configuration
    /// error rather than a silently reduced authority set.
    @discardableResult
    public func enable(
        _ capabilities: AgentCapabilitySet
    ) throws -> Snapshot {
        let missing = capabilities.subtracting(installedCapabilities)
        guard missing == .none else {
            throw AgentCapabilityMutationError.notInstalled(missing)
        }
        availableCapabilities = availableCapabilities.union(capabilities)
        hasLiveMutations = true
        return snapshot()
    }

    /// Strict exposure: only enabled capabilities can be shown to the model.
    @discardableResult
    public func expose(
        _ capabilities: AgentCapabilitySet
    ) throws -> Snapshot {
        let missing = capabilities.subtracting(availableCapabilities)
        guard missing == .none else {
            throw AgentCapabilityMutationError.notEnabled(missing)
        }
        visibleCapabilities = visibleCapabilities.union(capabilities)
        hasLiveMutations = true
        return snapshot()
    }

    @discardableResult
    public func disable(
        _ capabilities: AgentCapabilitySet
    ) -> Snapshot {
        availableCapabilities = availableCapabilities.subtracting(capabilities)
        hasLiveMutations = true
        visibleCapabilities = visibleCapabilities.intersecting(availableCapabilities)
        return snapshot()
    }

    @discardableResult
    public func unexpose(
        _ capabilities: AgentCapabilitySet
    ) -> Snapshot {
        visibleCapabilities = visibleCapabilities.subtracting(capabilities)
        hasLiveMutations = true
        return snapshot()
    }

    @discardableResult
    public func setAvailable(
        _ capabilities: AgentCapabilitySet
    ) -> Snapshot {
        availableCapabilities =
            capabilities.intersecting(
                installedCapabilities
            )
        visibleCapabilities =
            visibleCapabilities.intersecting(
                availableCapabilities
            )
        hasLiveMutations = true

        return snapshot()
    }

    @discardableResult
    public func setVisible(
        _ capabilities: AgentCapabilitySet
    ) -> Snapshot {
        visibleCapabilities =
            capabilities.intersecting(
                availableCapabilities
            )
        hasLiveMutations = true

        return snapshot()
    }

    @discardableResult
    public func reveal(
        _ capabilities: AgentCapabilitySet
    ) -> AgentCapabilitySet {
        let revealed =
            capabilities
                .intersecting(
                    availableCapabilities
                )
                .subtracting(
                    visibleCapabilities
                )

        visibleCapabilities =
            visibleCapabilities.union(
                revealed
            )
        if revealed != .none {
            hasLiveMutations = true
        }

        return revealed
    }

    @discardableResult
    public func hide(
        _ capabilities: AgentCapabilitySet
    ) -> AgentCapabilitySet {
        let hidden =
            visibleCapabilities.intersecting(
                capabilities
            )

        visibleCapabilities =
            visibleCapabilities.subtracting(
                capabilities
            )
        if hidden != .none {
            hasLiveMutations = true
        }

        return hidden
    }
}

public enum AgentCapabilityMutationError: Error, Sendable {
    case notInstalled(AgentCapabilitySet)
    case notEnabled(AgentCapabilitySet)
}
