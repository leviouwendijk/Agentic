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
    /// The exact preflight approved by the invocation owner, when available.
    public let approvedPreflight: ToolPreflight?

    public init(
        workspace: WorkspaceContext? = nil,
        catalog: Catalog = .none,
        capabilities: AgentCapabilityState? = nil,
        inspections: [CapabilityInspection] = [],
        approvedPreflight: ToolPreflight? = nil
    ) {
        self.workspace = workspace
        self.catalog = catalog
        self.capabilities = capabilities
        self.inspections = inspections
        self.approvedPreflight = approvedPreflight
    }

    public func using(
        workspace: WorkspaceContext?
    ) -> Self {
        .init(
            workspace: workspace,
            catalog: catalog,
            capabilities: capabilities,
            inspections: inspections,
            approvedPreflight: approvedPreflight
        )
    }

    /// Used only by reviewed invocation execution. Does not re-run preflight.
    public func using(approvedPreflight: ToolPreflight?) -> Self {
        .init(
            workspace: workspace,
            catalog: catalog,
            capabilities: capabilities,
            inspections: inspections,
            approvedPreflight: approvedPreflight
        )
    }
}
