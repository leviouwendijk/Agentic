import Agentic

/// Filters runtime-derived descriptions through the Agent's *live* authority.
/// No operation on this helper changes availability, visibility or installation.
enum CapabilityDiscovery {
    static func available(
        in context: ToolContext
    ) async throws -> (AgentCapabilityState.Snapshot, [CapabilityInspection]) {
        guard let state = context.capabilities else {
            throw FindCapabilitiesError.agentCapabilityStateRequired
        }
        let snapshot = await state.snapshot()
        let allowed = snapshot.available.intersecting(snapshot.installed)
        let entries = context.inspections.filter { entry in
            contains(entry.reference, in: allowed)
        }.sorted { lhs, rhs in
            if lhs.kind != rhs.kind { return lhs.kind < rhs.kind }
            return lhs.identifier < rhs.identifier
        }
        return (snapshot, entries)
    }

    static func contains(
        _ reference: CapabilityReference,
        in set: AgentCapabilitySet
    ) -> Bool {
        switch reference {
        case .tool(let id): set.tools.contains(id)
        case .program(let id): set.programs.contains(id)
        case .inference(let id): set.inferences.contains(id)
        case .agent(let id): set.agents.contains(id)
        }
    }
}
