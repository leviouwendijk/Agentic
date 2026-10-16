import Agentic
import AgenticContext
import Testing

private actor FindingFixture: Context.RecordResolving {
    private var originalRevision = "v1"

    func reviseSource(to value: String) { originalRevision = value }

    func resolve(_ pointer: Context.Pointer) async throws -> Context.Resolved {
        let revision = pointer.record == "failure" ? originalRevision : "finding-v1"
        return .init(
            pointer: .init(source: pointer.source, record: pointer.record,
                           selection: pointer.selection, revision: .recorded(revision)),
            messages: [.init(id: "finding.\(pointer.record)", role: .assistant,
                             content: .init(text: "Verified correction: use safe mode"))]
        )
    }
}

extension ContextDeterministicFlowTesting {
    static func runFindingLifecycle() async throws -> [TestDiagnostic] {
        let evidence = Context.Pointer(source: "fixture", record: "failure",
                                       revision: .recorded("v1"))
        let finding = Context.Record(id: "corrected-tool-call", kind: "finding",
            pointer: .init(source: "fixture", record: "correction",
                           revision: .recorded("finding-v1")),
            derivedFrom: [evidence])
        let irrelevant = Context.Record(id: "irrelevant-fact", kind: "finding",
            pointer: .init(source: "fixture", record: "other",
                           revision: .recorded("finding-v1")), derivedFrom: [evidence])
        let index = try Context.FindingIndex([
            .init(record: finding, terms: ["tool", "correction", "safe mode"]),
            .init(record: irrelevant, terms: ["weather", "temperature"])
        ])
        let resolver = FindingFixture()
        let selected = try await index.eligible(for: "tool correction", maximum: 2,
                                                using: resolver)
        try Expect.equal(selected.map(\.record.id), ["corrected-tool-call"],
                         "Unrelated record is excluded")
        let allocator = try Context.Allocator(policy: .init())
        try await allocator.createWorkingSet(id: "finding-lifecycle")
        try await allocator.apply(selected.map {
            .allocate(Context.FindingIndex.allocation(for: $0, required: true))
        }, to: "finding-lifecycle")
        let frame = try await allocator.prepareFrame(for: "finding-lifecycle",
            using: resolver, modelContextLimit: 50_000)
        try Expect.equal(frame.items.map(\.allocationID), ["corrected-tool-call"],
                         "Finding can be rehydrated from original source")
        let snapshot = try await allocator.snapshot("finding-lifecycle")
        try Expect.equal(snapshot.allocations.first?.dependencies, [evidence],
                         "Original recorded pointer survives allocation")
        await resolver.reviseSource(to: "v2")
        let stale = try await index.eligible(for: "tool correction", maximum: 2,
                                             using: resolver)
        try Expect.equal(stale.isEmpty, true, "Stale provenance excludes finding")
        let optionalAllocator = try Context.Allocator(policy: .init())
        try await optionalAllocator.createWorkingSet(id: "optional-stale")
        try await optionalAllocator.apply([
            .allocate(Context.FindingIndex.allocation(for: selected[0]))
        ], to: "optional-stale")
        let withoutStale = try await optionalAllocator.prepareFrame(
            for: "optional-stale", using: resolver, modelContextLimit: 50_000)
        try Expect.equal(withoutStale.items.isEmpty, true,
                         "Previously allocated optional stale finding cannot leak")
        try Expect.equal(withoutStale.skippedAllocationIDs, ["corrected-tool-call"],
                         "Stale omission is inspectable")
        return [.field("selected", String(selected.count)),
                .field("stale_excluded", String(stale.isEmpty))]
    }
}
