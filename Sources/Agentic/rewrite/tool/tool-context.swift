import Workspace

/// Execution-scoped context supplied to one Tool call.
///
/// The context is an immutable description of the invocation environment.
/// Agent owned mutable state is reached through the reference stored here
/// (capabilities), never mutated on this envelope itself.
public struct ToolContext: Sendable {
    public let workspace: WorkspaceContext?
    public let catalog: Catalog
    public let capabilities: AgentCapabilityState?
    public let inspections: [CapabilityInspection]

    public init(
        workspace: WorkspaceContext? = nil,
        catalog: Catalog = .none,
        capabilities: AgentCapabilityState? = nil,
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
