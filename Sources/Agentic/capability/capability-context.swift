import Workspace

/// What a capability sees when it runs: a Tool receives it with each call, a Program
/// through `ProgramContext.capability`.
///
/// The context is an immutable description of the invocation environment.
/// Capability state is exposed through an observation-only interface.
/// Installation, enablement and exposure remain trusted control-plane
/// operations, not CapabilityContext operations.
public struct CapabilityContext: Sendable {
    public let workspace: WorkspaceContext?
    public let catalog: Catalog
    public let capabilities: (any AgentCapabilityObserving)?
    /// The capabilities the running agent may invoke, with their contracts: available
    /// ones only, as the host captured them for this invocation. Discovery narrows them
    /// further against the live state.
    public let inspections: [CapabilityInspection]
    public let services: CapabilityServices

    public init(
        workspace: WorkspaceContext? = nil,
        catalog: Catalog = .none,
        capabilities: (any AgentCapabilityObserving)? = nil,
        inspections: [CapabilityInspection] = [],
        services: CapabilityServices = .init()
    ) {
        self.workspace = workspace
        self.catalog = catalog
        self.capabilities = capabilities
        self.inspections = inspections
        self.services = services
    }

    public func using(
        workspace: WorkspaceContext?
    ) -> Self {
        .init(
            workspace: workspace,
            catalog: catalog,
            capabilities: capabilities,
            inspections: inspections,
            services: services
        )
    }

    /// Resolve a trusted dependency for this invocation.
    public func require<Service: Sendable>(
        _ type: Service.Type
    ) throws -> Service {
        try services.require(type)
    }

    /// A trusted execution host may replace the dependency scope.
    public func using(services: CapabilityServices) -> Self {
        .init(
            workspace: workspace,
            catalog: catalog,
            capabilities: capabilities,
            inspections: inspections,
            services: services
        )
    }

}
