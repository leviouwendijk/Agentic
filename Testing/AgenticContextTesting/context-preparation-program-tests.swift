import Agentic
import AgenticContext
import Testing

private struct PreparationFixture: Context.RecordResolving {
    func resolve(_ pointer: Context.Pointer) async throws -> Context.Resolved {
        .init(pointer: .init(source: pointer.source, record: pointer.record,
                             selection: pointer.selection, revision: .recorded("v1")),
              messages: [.init(id: "prepared.\(pointer.record)", role: .assistant,
                               content: .init(text: "Verified evidence"))])
    }
}

extension ContextDeterministicFlowTesting {
    static func runBoundedPreparation() async throws -> [TestDiagnostic] {
        let index = try Context.FindingIndex((0..<9).map { offset in
            .init(record: Context.Record(id: "record-\(offset)", kind: "finding",
                pointer: .init(source: "fixture", record: "record-\(offset)",
                               revision: .recorded("v1")),
                derivedFrom: [.init(source: "fixture", record: "original",
                                    revision: .recorded("v1"))]), terms: ["tool", "correction"])
        })
        let program = ContextPreparationProgram(index: index,
            resolver: PreparationFixture(), maximumFindings: 3)
        let ids = try await program.run("tool correction", in: ProgramContext())
        try Expect.equal(ids, ["record-0", "record-1", "record-2"],
                         "No inference service falls back to bounded ordered candidates")
        let allocations = try await program.allocations(ids: ids + ["forged"],
                                                        query: "tool correction")
        try Expect.equal(allocations.map(\.id), ids,
                         "Forged identifiers never become allocations")
        let adapter = ContextProgramPreparation(program: program, context: ProgramContext())
        let request = AgentRequest(messages: [
            .init(id: "user", role: .user, content: .init(text: "tool correction"))
        ])
        let prepared = try await adapter.allocations(for: request)
        try Expect.equal(prepared.map(\.id), ids,
                         "Program connects through bounded optional preparation seam")
        return [.field("bounded", String(ids.count))]
    }
}
