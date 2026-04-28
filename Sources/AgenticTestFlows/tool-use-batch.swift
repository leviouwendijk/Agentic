import Agentic
import Foundation
import Primitives
import TestFlows

extension AgenticFlowTesting {
    static func runToolUseBatchObserve() async throws -> [TestFlowDiagnostic] {
        let adapter = BatchModelAdapter(
            scenario: .observe
        )
        var registry = ToolRegistry()

        try registry.register(
            BatchObserveTool()
        )

        let runner = AgentRunner(
            adapter: adapter,
            configuration: .init(
                maximumIterations: 4,
                autonomyMode: .auto_observe,
                historyPersistenceMode: .checkpointmutation
            ),
            toolRegistry: registry
        )

        let result = try await runner.run(
            request(),
            sessionID: "tool-use-batch-observe"
        )

        let requests = await adapter.requests()
        let secondRequest = try Expect.notNil(
            requests.dropFirst().first,
            "second model request"
        )
        let results = toolResults(
            in: secondRequest
        )

        try Expect.equal(
            results.count,
            2,
            "batched observe tool result count"
        )

        try Expect.equal(
            results.filter(\.isError).count,
            0,
            "batched observe error count"
        )

        try Expect.equal(
            result.response?.message.content.text,
            "batch observe ok",
            "final response"
        )

        return [
            .field(
                "tool_results",
                results.map(\.toolCallID).joined(separator: ",")
            ),
            .field(
                "events",
                result.events.map(\.kind.rawValue).joined(separator: ",")
            )
        ]
    }

    static func runToolUseBatchApprovalSkip() async throws -> [TestFlowDiagnostic] {
        let adapter = BatchModelAdapter(
            scenario: .approval
        )
        let approval = BatchApprovalHandler(
            firstDecision: .needshuman
        )
        var registry = ToolRegistry()

        try registry.register(
            BatchObserveTool()
        )
        try registry.register(
            BatchMutateTool()
        )

        let historyStore = FileHistoryStore(
            sessionsdir: FileManager.default.temporaryDirectory
                .appendingPathComponent(
                    "agentic-tool-use-batch-approval-\(UUID().uuidString)",
                    isDirectory: true
                )
        )

        let runner = AgentRunner(
            adapter: adapter,
            configuration: .init(
                maximumIterations: 6,
                autonomyMode: .auto_observe,
                historyPersistenceMode: .checkpointmutation
            ),
            toolRegistry: registry,
            approvalHandler: approval,
            historyStore: historyStore
        )

        let initial = try await runner.run(
            request(),
            sessionID: "tool-use-batch-approval-skip"
        )

        let pending = try Expect.notNil(
            initial.pendingApproval,
            "pending approval"
        )

        try Expect.equal(
            pending.toolCall.name,
            BatchMutateTool.identifier.rawValue,
            "pending tool"
        )

        let resumed = try await runner.resume(
            sessionID: initial.sessionID,
            approvalDecision: .approved
        )

        let requests = await adapter.requests()
        let finalRequest = try Expect.notNil(
            requests.last,
            "final model request"
        )
        let results = toolResults(
            in: finalRequest
        )

        try Expect.equal(
            results.count,
            3,
            "final tool result count"
        )

        let skipped = try Expect.notNil(
            results.first(where: { result in
                result.toolCallID == "observe-after-mutation"
            }),
            "skipped sibling result"
        )

        try Expect.equal(
            skipped.isError,
            true,
            "skipped sibling is error"
        )

        try Expect.equal(
            resumed.response?.message.content.text,
            "batch approval ok",
            "final response"
        )

        return [
            .field(
                "pending",
                pending.toolCall.id
            ),
            .field(
                "tool_results",
                results.map { result in
                    "\(result.toolCallID):\(result.isError)"
                }.joined(separator: ",")
            ),
            .field(
                "events",
                resumed.events.map { event in
                    event.kind.rawValue
                }.joined(separator: ",")
            )
        ]
    }

    static func runToolUseBatchDenialSkip() async throws -> [TestFlowDiagnostic] {
        let adapter = BatchModelAdapter(
            scenario: .denial
        )
        let approval = BatchApprovalHandler(
            firstDecision: .needshuman
        )
        var registry = ToolRegistry()

        try registry.register(
            BatchObserveTool()
        )
        try registry.register(
            BatchMutateTool()
        )

        let historyStore = FileHistoryStore(
            sessionsdir: FileManager.default.temporaryDirectory
                .appendingPathComponent(
                    "agentic-tool-use-batch-denial-\(UUID().uuidString)",
                    isDirectory: true
                )
        )

        let runner = AgentRunner(
            adapter: adapter,
            configuration: .init(
                maximumIterations: 6,
                autonomyMode: .auto_observe,
                historyPersistenceMode: .checkpointmutation
            ),
            toolRegistry: registry,
            approvalHandler: approval,
            historyStore: historyStore
        )

        let initial = try await runner.run(
            request(),
            sessionID: "tool-use-batch-denial-skip"
        )

        _ = try Expect.notNil(
            initial.pendingApproval,
            "pending approval"
        )

        let resumed = try await runner.resume(
            sessionID: initial.sessionID,
            approvalDecision: .denied
        )

        let requests = await adapter.requests()
        let finalRequest = try Expect.notNil(
            requests.last,
            "final model request"
        )
        let results = toolResults(
            in: finalRequest
        )

        try Expect.equal(
            results.count,
            3,
            "final tool result count"
        )

        try Expect.equal(
            results.filter(\.isError).count,
            2,
            "denied plus skipped error count"
        )

        try Expect.equal(
            resumed.response?.message.content.text,
            "batch denial ok",
            "final response"
        )

        return [
            .field(
                "tool_results",
                results.map { result in
                    "\(result.toolCallID):\(result.isError)"
                }.joined(separator: ",")
            ),
            .field(
                "events",
                resumed.events.map { event in
                    event.kind.rawValue
                }.joined(separator: ",")
            )
        ]
    }
}

private enum BatchScenario: Sendable, Hashable {
    case observe
    case approval
    case denial
}

private actor BatchModelState {
    var requests: [AgentRequest] = []

    func append(
        _ request: AgentRequest
    ) {
        requests.append(
            request
        )
    }

    func all() -> [AgentRequest] {
        requests
    }
}

private struct BatchModelAdapter: AgentModelAdapter {
    let scenario: BatchScenario
    let state = BatchModelState()

    var response: AgentModelResponseProviding {
        BatchModelProvider(
            scenario: scenario,
            state: state
        )
    }

    func requests() async -> [AgentRequest] {
        await state.all()
    }
}

private struct BatchModelProvider: AgentModelResponseProviding {
    let scenario: BatchScenario
    let state: BatchModelState

    func buffered(
        request: AgentRequest
    ) async throws -> AgentResponse {
        await state.append(
            request
        )

        let results = toolResults(
            in: request
        )

        if !results.isEmpty {
            return .init(
                message: .init(
                    role: .assistant,
                    text: finalText(
                        results
                    )
                ),
                stopReason: .end_turn
            )
        }

        return .init(
            message: .init(
                role: .assistant,
                content: .init(
                    blocks: toolCallBlocks()
                )
            ),
            stopReason: .tool_use
        )
    }

    func stream(
        request: AgentRequest
    ) -> AsyncThrowingStream<AgentStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let response = try await buffered(
                        request: request
                    )

                    continuation.yield(
                        .completed(
                            response
                        )
                    )
                    continuation.finish()
                } catch {
                    continuation.finish(
                        throwing: error
                    )
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func toolCallBlocks() -> [AgentContentBlock] {
        switch scenario {
        case .observe:
            return [
                .tool_call(
                    observeCall(
                        id: "observe-one",
                        text: "one"
                    )
                ),
                .tool_call(
                    observeCall(
                        id: "observe-two",
                        text: "two"
                    )
                )
            ]

        case .approval,
             .denial:
            return [
                .tool_call(
                    observeCall(
                        id: "observe-before-mutation",
                        text: "before"
                    )
                ),
                .tool_call(
                    mutateCall(
                        id: "approval-mutation"
                    )
                ),
                .tool_call(
                    observeCall(
                        id: "observe-after-mutation",
                        text: "after"
                    )
                )
            ]
        }
    }

    func observeCall(
        id: String,
        text: String
    ) -> AgentToolCall {
        AgentToolCall(
            id: id,
            name: BatchObserveTool.identifier.rawValue,
            input: try! JSONToolBridge.encode(
                BatchObserveInput(
                    text: text
                )
            )
        )
    }

    func mutateCall(
        id: String
    ) -> AgentToolCall {
        AgentToolCall(
            id: id,
            name: BatchMutateTool.identifier.rawValue,
            input: .object([:])
        )
    }

    func finalText(
        _ results: [AgentToolResult]
    ) -> String {
        switch scenario {
        case .observe:
            return "batch observe ok"

        case .approval:
            return "batch approval ok"

        case .denial:
            return "batch denial ok"
        }
    }
}

private struct BatchApprovalHandler: ToolApprovalHandler {
    var firstDecision: ApprovalDecision

    func decide(
        on preflight: ToolPreflight,
        requirement: ApprovalRequirement
    ) async throws -> ApprovalDecision {
        if !requirement.requiresHumanReview {
            return requirement.decision
        }

        return firstDecision
    }
}

private struct BatchObserveTool: StaticAgentTool {
    static let identifier: AgentToolIdentifier = "batch_observe"
    static let description = "Observe a small test payload."
    static let risk: ActionRisk = .observe

    func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        let decoded = try JSONToolBridge.decode(
            BatchObserveInput.self,
            from: input
        )

        return try JSONToolBridge.encode(
            BatchObserveOutput(
                text: decoded.text
            )
        )
    }
}

private struct BatchMutateTool: StaticAgentTool {
    static let identifier: AgentToolIdentifier = "batch_mutate"
    static let description = "Perform a bounded test mutation."
    static let risk: ActionRisk = .boundedmutate

    func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        _ = input
        _ = workspace

        return .object([
            "ok": .bool(true)
        ])
    }
}

private struct BatchObserveInput: Sendable, Codable, Hashable {
    var text: String
}

private struct BatchObserveOutput: Sendable, Codable, Hashable {
    var text: String
}

private func toolResults(
    in request: AgentRequest
) -> [AgentToolResult] {
    request.messages
        .flatMap(\.content.blocks)
        .compactMap { block in
            guard case .tool_result(let result) = block else {
                return nil
            }

            return result
        }
}
