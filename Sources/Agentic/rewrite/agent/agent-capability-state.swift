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

    private let installedCapabilities:
        AgentCapabilitySet
    private var availableCapabilities:
        AgentCapabilitySet
    private var visibleCapabilities:
        AgentCapabilitySet

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
        _ snapshot: Snapshot
    ) -> Snapshot {
        availableCapabilities =
            snapshot.available.intersecting(
                installedCapabilities
            )
        visibleCapabilities =
            snapshot.visible.intersecting(
                availableCapabilities
            )

        return self.snapshot()
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

        return hidden
    }
}
