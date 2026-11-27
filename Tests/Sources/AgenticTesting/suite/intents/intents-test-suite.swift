import Agentic
import AgenticIntents
import Foundation
import IO
import Primitives
import Schema
import Testing

enum IntentsTestSuite {
    static let testSuite = TestSuite(
        "intents",
        title: "Deferred tool calls"
    ) {
        Test("intents-defer-review-execute", tags: ["intents", "lifecycle"]) { context in
            await context.record(contentsOf: try await IntentsTesting.deferReviewExecute())
        }
        Test("intents-review-guards", tags: ["intents", "guards"]) { context in
            await context.record(contentsOf: try await IntentsTesting.reviewGuards())
        }
        Test("intents-deferring-handler", tags: ["intents", "approval"]) { context in
            await context.record(contentsOf: try await IntentsTesting.deferringHandler())
        }
    }
}

enum IntentsTesting {
    /// A deferred call is stored, survives a second manager over the same
    /// directory, runs once after approval and records its output.
    static func deferReviewExecute() async throws -> [TestDiagnostic] {
        try await withDirectory { directory in
            let probe = AppendProbe()
            let tools = try executor(probe: probe)
            let manager = Intents.Manager(store: Intents.FileStore(directory: directory))
            let intent = try await deferredIntent(tools: tools, manager: manager, value: "alpha")

            try Expect.equal(intent.status, .pending, "a deferred call starts pending")
            try Expect.equal(intent.sessionID, "session-a", "the intent keeps its session")
            try Expect.equal(await probe.values(), [], "deferring runs nothing")

            try await expectIntentError("an unreviewed intent does not run") {
                _ = try await manager.claim(intent.id)
            } matching: {
                if case .notApproved(_, .pending) = $0 { return true }
                return false
            }

            let approved = try await manager.review(intent.id, decision: .approve, reviewer: "owner", note: "fine")
            try Expect.equal(approved.status, .approved, "approval is recorded")
            try Expect.equal(approved.review?.reviewer, "owner", "the reviewer is recorded")
            try Expect.equal(await probe.values(), [], "approving does not run the call")

            let other = Intents.Manager(store: Intents.FileStore(directory: directory))
            let executed = try await Intents.Executor(manager: other, tools: tools)
                .execute(intent.id, in: CapabilityContext())

            try Expect.equal(executed.status, .executed, "an approved intent runs")
            try Expect.equal(await probe.values(), ["alpha"], "the prepared plan ran exactly once")
            try Expect.equal(executed.execution?.outcome, .succeeded, "the record says it succeeded")
            let output = try Expect.notNil(executed.execution?.output, "the record keeps the output")
            try Expect.equal(
                try output.value(forDotPath: "result").stringValue,
                "appended:alpha",
                "the record keeps the tool's output"
            )
            try Expect.equal(
                executed.execution?.attemptID,
                executed.attempt?.id,
                "the record belongs to the claimed attempt"
            )

            try await expectIntentError("an executed intent does not run again") {
                _ = try await Intents.Executor(manager: manager, tools: tools)
                    .execute(intent.id, in: CapabilityContext())
            } matching: {
                if case .notApproved(_, .executed) = $0 { return true }
                return false
            }
            try Expect.equal(await probe.values(), ["alpha"], "nothing ran twice")

            let listed = try await manager.list(statuses: [.executed], sessionID: "session-a")
            try Expect.equal(listed.map(\.id), [intent.id], "listing filters by status and session")
            try Expect.equal(
                try await manager.list(sessionID: "session-b").isEmpty,
                true,
                "other sessions don't see it"
            )

            return [
                .field("intent", intent.id.raw),
                .field("status", executed.status.rawValue),
            ]
        }
    }

    /// Denied, expired and doubly claimed intents never run.
    static func reviewGuards() async throws -> [TestDiagnostic] {
        try await withDirectory { directory in
            let probe = AppendProbe()
            let tools = try executor(probe: probe)
            let manager = Intents.Manager(store: Intents.FileStore(directory: directory))

            let denied = try await deferredIntent(tools: tools, manager: manager, value: "denied")
            _ = try await manager.review(denied.id, decision: .deny, note: "no")
            try await expectIntentError("a denied intent can't be reviewed again") {
                _ = try await manager.review(denied.id, decision: .approve)
            } matching: {
                if case .notReviewable(_, .denied) = $0 { return true }
                return false
            }

            let stale = try await deferredIntent(
                tools: tools,
                manager: manager,
                value: "stale",
                expiresAt: Date(timeIntervalSinceNow: -60)
            )
            try await expectIntentError("approving an expired intent expires it") {
                _ = try await manager.review(stale.id, decision: .approve)
            } matching: {
                if case .expired = $0 { return true }
                return false
            }
            try Expect.equal(try await manager.intent(stale.id).status, .expired, "the expiry is stored")
            try Expect.equal(
                try await manager.list().map(\.id).contains(stale.id),
                true,
                "an expired intent stays listed once it is marked expired"
            )

            let claimed = try await deferredIntent(tools: tools, manager: manager, value: "claimed")
            _ = try await manager.review(claimed.id, decision: .approve)
            _ = try await manager.claim(claimed.id)
            try await expectIntentError("a claimed intent can't be claimed twice") {
                _ = try await manager.claim(claimed.id)
            } matching: {
                if case .notApproved(_, .executing) = $0 { return true }
                return false
            }

            try await expectIntentError("ids that could leave the directory are rejected") {
                _ = try Intents.Intent.ID("../escape")
            } matching: {
                if case .invalidID = $0 { return true }
                return false
            }

            try Expect.equal(await probe.values(), [], "no guarded intent ran")
            return [.field("guards", "deny,expire,claim,id")]
        }
    }

    /// Only calls that need a person are deferred, and never the tools
    /// that review intents.
    static func deferringHandler() async throws -> [TestDiagnostic] {
        let handler = Intents.DeferringApprovalHandler()
        let preflight = ToolPreflight(tool: AppendTool.definition.identifier, risk: .boundedmutate, summary: "append")
        let reviewing = ToolPreflight(
            tool: Intents.Tools.ReviewIntent.identifier,
            risk: .privileged,
            summary: "approve"
        )

        try Expect.equal(
            try await handler.decide(on: preflight, requirement: .needs_human_review),
            .deferred,
            "a call needing review is deferred"
        )
        try Expect.equal(
            try await handler.decide(on: preflight, requirement: .no_approval_needed),
            .approved,
            "a call the policy allows runs"
        )
        try Expect.equal(
            try await handler.decide(on: preflight, requirement: .denied_forbidden),
            .denied,
            "a forbidden call stays denied"
        )
        try Expect.equal(
            try await handler.decide(on: reviewing, requirement: .needs_human_review),
            .denied,
            "a run never queues the review of intents"
        )

        let result = try await ToolExecutor(
            registry: try ToolRegistry { AppendTool(probe: AppendProbe()) },
            policy: .init(autonomyMode: .auto_observe)
        ).invoke(
            appendInvocation("core"),
            context: CapabilityContext(),
            approvalHandler: handler
        )
        try Expect.equal(
            result.outcome,
            .interrupted(.human_review),
            "without a store, a deferral is an unresolved review"
        )

        return [.field("decisions", "deferred,approved,denied,denied")]
    }
}

private extension IntentsTesting {
    static func executor(
        probe: AppendProbe
    ) throws -> ToolExecutor {
        ToolExecutor(
            registry: try ToolRegistry { AppendTool(probe: probe) },
            policy: .init(autonomyMode: .auto_observe)
        )
    }

    static func appendInvocation(
        _ value: String
    ) throws -> ToolInvocation {
        ToolInvocation(
            id: "append-\(value)",
            tool: AppendTool.definition.identifier,
            arguments: try JSONValue.encoding(AppendInput(value: value))
        )
    }

    /// Reviews the call as a run would, then stores it as the loop does when
    /// the handler defers.
    static func deferredIntent(
        tools: ToolExecutor,
        manager: Intents.Manager,
        value: String,
        expiresAt: Date? = nil
    ) async throws -> Intents.Intent {
        let review = try await tools.review(
            try appendInvocation(value),
            context: CapabilityContext()
        )
        try Expect.equal(review.requirement, .needs_human_review, "the fixture needs review")
        let operation = try Expect.notNil(review.preparedOperation, "the fixture prepares its plan")

        return try await manager.create(
            .init(
                sessionID: "session-a",
                invocation: .init(review: review, operation: operation),
                expiresAt: expiresAt
            )
        )
    }

    static func expectIntentError(
        _ message: String,
        _ operation: () async throws -> Void,
        matching: (Intents.Error) -> Bool
    ) async throws {
        do {
            try await operation()
        } catch let error as Intents.Error {
            try Expect.equal(matching(error), true, "\(message): got \(error)")
            return
        }
        try Expect.equal(false, true, "\(message): nothing was thrown")
    }

    static func withDirectory<T>(
        _ body: (URL) async throws -> T
    ) async throws -> T {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("agentic-intents-\(UUID().uuidString)", isDirectory: true)
        defer {
            try? FileSystem.default.remove(directory)
        }
        return try await body(directory)
    }
}

private actor AppendProbe {
    private var appended: [String] = []

    func append(
        _ value: String
    ) {
        appended.append(value)
    }

    func values() -> [String] {
        appended
    }
}

private struct AppendInput: Sendable, Codable, Hashable, JSONSchemaProviding {
    let value: String

    static var jsonschema: JSONSchema {
        JSONSchema.object {
            JSONSchema.string("value", required: true)
        }
    }
}

private struct AppendOutput: Sendable, Codable, Hashable, JSONSchemaProviding {
    let result: String

    static var jsonschema: JSONSchema {
        JSONSchema.object {
            JSONSchema.string("result", required: true)
        }
    }
}

private enum AppendOperation: AgentPreparedOperation {
    struct Plan: Sendable, Codable, Hashable {
        let value: String
    }

    static let schema = PreparedOperation.Schema(
        identifier: "fixture.append",
        version: .init(major: 1, minor: 0, patch: 0)
    )
}

/// Needs review under `auto_observe` and executes only its prepared plan.
private struct AppendTool: Tool {
    typealias Input = AppendInput
    typealias Output = AppendOutput

    static let definition = ToolDefinition(
        identifier: "fixture_append",
        purpose: "Prepared append fixture.",
        risk: .boundedmutate
    )

    let probe: AppendProbe

    func prepare(
        _ input: Input,
        in _: CapabilityContext
    ) async throws -> CapabilityPreparation<ToolPreflight> {
        .init(
            review: .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Append \(input.value)"
            ),
            operation: try AppendOperation.envelope(.init(value: input.value))
        )
    }

    func call(
        _: Input,
        in _: CapabilityContext
    ) async throws -> Output {
        throw ToolPreparationError.prepared_operation_required
    }

    func call(
        _: Input,
        prepared operation: PreparedOperation.Envelope?,
        in _: CapabilityContext
    ) async throws -> Output {
        guard let operation else {
            throw ToolPreparationError.prepared_operation_required
        }
        let plan = try AppendOperation.plan(from: operation)
        await probe.append(plan.value)
        return .init(result: "appended:\(plan.value)")
    }
}
