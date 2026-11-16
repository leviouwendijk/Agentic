import Agentic
import AgenticContext
import Foundation
import Testing

// Minimized from session 87C9299B: the preceding findings disappear,
// return, then disappear again as source-result pressure changes.
// All source text and provider continuation here are synthetic.
struct ContextIncidentFixture {
    static let findingsID = "incident.findings"
    static let findings = "A: expose wrapping; B: replay tabs safely; C: recognize tab boundaries."

    let requests: [AgentRequest]
    let historyBudget: Int

    init() throws {
        let initial = AgentRequest(messages: [
            .init(id: "incident.system", role: .system,
                  content: .init(text: "Follow the current task.")),
            .init(id: "incident.review", role: .user,
                  content: .init(text: "Review the word-wrapping change.")),
        ] + Self.exchange("previous", output: String(
            repeating: "previous source line\n", count: 300
        )) + [
            .init(id: Self.findingsID, role: .assistant,
                  content: .init(text: Self.findings),
                  providerContinuation: ["openai": try Self.continuation()]),
            .init(id: "incident.followup", role: .user,
                  content: .init(text: "Implement all three points from your previous answer.")),
        ])
        let baseline = try Self.prepare(initial, delivery: .supplement)
        historyBudget = baseline.measurement.estimatedInputTokens + 512

        var pending = initial
        pending.messages += Self.exchange("fresh", output: String(
            repeating: "unseen source line for the current implementation\n", count: 2_000
        ))
        var seen = pending
        seen.messages.append(.init(
            id: "incident.seen", role: .assistant,
            content: .init(text: "The latest source result has been read.")
        ))
        var pendingAgain = seen
        pendingAgain.messages += Self.exchange("fresh-again", output: String(
            repeating: "another unseen source line for the implementation\n", count: 2_000
        ))
        requests = [initial, pending, seen, pendingAgain, pendingAgain]
    }

    func preparations() throws -> [Context.InferencePreparation] {
        try requests.map {
            try Self.prepare($0, delivery: .dynamic, historyBudget: historyBudget)
        }
    }

    static func prepare(
        _ request: AgentRequest,
        delivery: Context.InferenceDelivery,
        historyBudget: Int = 100_000
    ) throws -> Context.InferencePreparation {
        try Context.InferencePreparer.prepare(
            request: request,
            frame: .init(
                workingSetID: "incident", items: [], skippedAllocationIDs: [],
                inputBudget: 0, estimatedInputTokens: 0
            ),
            delivery: delivery,
            maximumInputTokens: 100_000,
            historyPolicy: .init(maximumTurns: 4, maximumTokens: historyBudget)
        )
    }

    private static func exchange(_ id: String, output: String) -> [Message] {
        let call = FunctionCall(
            id: id, name: "read_file",
            input: .object(["path": .string("Sources/Layout.swift")])
        )
        return [
            .init(id: "assistant.\(id)", role: .assistant,
                  content: .init(blocks: [.call(call)])),
            .init(id: "tool.\(id)", role: .tool,
                  content: .init(blocks: [
                    .result(.init(call: call.reference, output: .string(output))),
                  ])),
        ]
    }

    private static func continuation() throws -> String {
        let output: [[String: Any]] = [
            [
                "type": "reasoning",
                "id": "rs_fixture",
                "summary": [],
                "encrypted_content": String(repeating: "fixture-only-", count: 800),
            ],
            [
                "type": "message",
                "id": "msg_fixture",
                "role": "assistant",
                "status": "completed",
                "content": [
                    ["type": "output_text", "text": findings, "annotations": []],
                ],
            ],
        ]
        return String(
            decoding: try JSONSerialization.data(withJSONObject: output, options: .sortedKeys),
            as: UTF8.self
        )
    }
}

extension ContextDeterministicFlowTesting {
    static func runIncidentBaseline() throws -> [TestDiagnostic] {
        let fixture = try ContextIncidentFixture()
        let canonical = fixture.requests
        let preparations = try fixture.preparations()
        var retention: [String] = []

        for (request, prepared) in zip(canonical, preparations) {
            let ids = Set(request.messages.map(\.id))
            let retained = Set(prepared.history.retained.map(\.messageID))
            let omitted = Set(prepared.history.omitted.map(\.messageID))
            try Expect.equal(retained.union(omitted), ids,
                "The selection accounts for every canonical message")
            try Expect.true(retained.isDisjoint(with: omitted),
                "A message cannot be both retained and omitted")
            try Expect.true(retained.contains("incident.followup"),
                "The dependent user request survives")
            try Expect.equal(Set(prepared.request.messages.map(\.id)), retained,
                "The history manifest describes the actual prepared request")
            let omissions = Set((prepared.history.changes ?? []).filter {
                $0.reason == .turn_budget || $0.reason == .exchange_budget
            }.map(\.messageID))
            try Expect.equal(omissions, omitted, "Every omission has a structured reason")
            try Expect.true((prepared.history.changes ?? []).allSatisfy {
                ids.contains($0.messageID)
            }, "Every decision names canonical evidence")
            retention.append(String(retained.contains(ContextIncidentFixture.findingsID)))
        }
        try Expect.equal(fixture.requests, canonical, "Preparation leaves canonical history intact")
        try Expect.equal(preparations[3].history, preparations[4].history,
            "Repeated preparation produces identical decision evidence")
        let encoded = try JSONEncoder().encode(preparations[0].history)
        try Expect.equal(
            try JSONDecoder().decode(Context.HistorySelection.self, from: encoded),
            preparations[0].history, "Decision evidence survives serialization"
        )
        let legacy = Data(#"{"retained":[],"omitted":[],"elided":[]}"#.utf8)
        try Expect.equal(
            try JSONDecoder().decode(Context.HistorySelection.self, from: legacy).changes,
            nil, "Old records do not invent historical decisions"
        )
        try Expect.equal(preparations[3].request, preparations[4].request,
            "Identical preparation inputs yield identical requests")
        return [
            .field("incident", "87C9299B steps 351/401/416/430/444/458/466"),
            .field("findings_retained", retention.joined(separator: ", ")),
            .field("history_budget", String(fixture.historyBudget)),
            .field("selected_messages", preparations.map {
                String($0.request.messages.count)
            }.joined(separator: ", ")),
        ]
    }

    static func runIncidentContinuity() throws {
        let fixture = try ContextIncidentFixture()
        for (stage, prepared) in try fixture.preparations().enumerated() {
            try Expect.true(
                prepared.request.messages.contains {
                    $0.id == ContextIncidentFixture.findingsID
                        && $0.content.text == ContextIncidentFixture.findings
                },
                "Stage \(stage) must retain the findings referenced by the follow-up"
            )
        }
    }

    static func runIncidentReplayMeasurement() throws -> [TestDiagnostic] {
        let fixture = try ContextIncidentFixture()
        let stored = fixture.requests[0]
        var visibleOnly = stored
        for index in visibleOnly.messages.indices {
            visibleOnly.messages[index].providerContinuation = nil
        }
        let withReplay = try ContextIncidentFixture.prepare(stored, delivery: .supplement)
        let withoutReplay = try ContextIncidentFixture.prepare(visibleOnly, delivery: .supplement)
        try Expect.equal(
            withReplay.request.messages.map(\.content),
            withoutReplay.request.messages.map(\.content),
            "The visible dialogue is identical in both measurement samples"
        )
        try Expect.equal(withReplay.request, stored, "Measurement preserves native replay data")
        // These are storage-representation estimates, not measured provider
        // usage. Do not assert that opaque reasoning has zero context cost.
        return [
            .field("stored_estimate", String(withReplay.measurement.estimatedInputTokens)),
            .field("visible_only_estimate", String(withoutReplay.measurement.estimatedInputTokens)),
            .field("stored_bytes", String(withReplay.measurement.serializedRequestBytes)),
            .field("visible_only_bytes", String(withoutReplay.measurement.serializedRequestBytes)),
        ]
    }
}
