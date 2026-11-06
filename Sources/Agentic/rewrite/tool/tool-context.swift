import Workspace

/// Execution-scoped context supplied to one Tool call.
///
/// The context is an immutable description of the invocation environment.
/// Capability state is exposed through an observation-only interface.
/// Installation, enablement and exposure remain trusted control-plane
/// operations, not ToolContext operations.
public struct ToolContext: Sendable {
    public let workspace: WorkspaceContext?
    public let catalog: Catalog
    public let capabilities: (any AgentCapabilityObserving)?
    public let inspections: [CapabilityInspection]
    public let services: ToolServices

    public init(
        workspace: WorkspaceContext? = nil,
        catalog: Catalog = .none,
        capabilities: (any AgentCapabilityObserving)? = nil,
        inspections: [CapabilityInspection] = [],
        services: ToolServices = .init()
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

}
