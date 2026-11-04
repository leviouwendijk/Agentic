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

    public init(
        workspace: WorkspaceContext? = nil,
        catalog: Catalog = .none,
        capabilities: (any AgentCapabilityObserving)? = nil,
        inspections: [CapabilityInspection] = []
    ) {
        self.workspace = workspace
        self.catalog = catalog
        self.capabilities = capabilities
        self.inspections = inspections
    }

    public func using(
        workspace: WorkspaceContext?
    ) -> Self {
        .init(
            workspace: workspace,
            catalog: catalog,
            capabilities: capabilities,
            inspections: inspections
        )
    }

}
