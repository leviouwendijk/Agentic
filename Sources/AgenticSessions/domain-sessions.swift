import Agentic

/// Read-only introspection over Agentic sessions: their history, durable
/// log, catalog, approvals and artifacts. A standard harness capability,
/// independent of any runtime.
///
/// Tools resolve their sources from the invocation's services, so the host
/// decides which (if any) an Agent may read: `Sessions.HistoryStore`,
/// `any Sessions.LogReading` and `any Sessions.CatalogReading`.
@Domain("sessions", aliases: ["session"])
public enum Sessions {}
