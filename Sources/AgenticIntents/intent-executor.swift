import Agentic
import Foundation

public extension Intents {
    /// Runs approved intents through the same tool path as an approved live
    /// call: the tool executes exactly the operation it prepared.
    struct Executor: Sendable {
        public let manager: Manager
        public let tools: ToolExecutor

        public init(
            manager: Manager,
            tools: ToolExecutor
        ) {
            self.manager = manager
            self.tools = tools
        }

        /// Claims the intent, runs its call once and records the outcome.
        /// The current policy still applies: a tool it now forbids fails.
        public func execute(
            _ id: Intent.ID,
            in context: ToolContext
        ) async throws -> Intent {
            let intent = try await manager.claim(id)
            guard let attempt = intent.attempt else {
                throw Error.attemptMismatch(id, expected: nil, actual: "none")
            }

            let stored = intent.invocation.review
            let review = ToolInvocation.Review(
                invocation: stored.invocation,
                preflight: stored.preflight,
                requirement: tools.policy.evaluate(stored.preflight),
                references: stored.references,
                preparedOperation: intent.operation
            )

            let record: Execution.Record
            do {
                let result = try await tools.invoke(
                    review,
                    context: context,
                    approvalHandler: ReviewedApproval()
                )
                record = Self.record(
                    result.outcome,
                    tool: intent.tool,
                    attempt: attempt
                )
            } catch {
                record = .init(
                    attemptID: attempt.id,
                    outcome: .failed,
                    summary: "\(intent.tool.rawValue) failed before it returned a result.",
                    startedAt: attempt.startedAt,
                    error: String(describing: error)
                )
            }

            return try await manager.finish(id, with: record)
        }
    }

    /// For unattended runs: where a person would be asked, store the call as
    /// an intent instead. Intent tools are denied rather than deferred, so a
    /// run can never queue the approval of its own intents.
    struct DeferringApprovalHandler: ToolApprovalHandler {
        public init() {}

        public func decide(
            on preflight: ToolPreflight,
            requirement: ApprovalRequirement
        ) async throws -> ApprovalDecision {
            guard requirement == .needs_human_review else {
                return requirement.decision
            }
            return Intents.reviewingTools.contains(preflight.tool)
                ? .denied
                : .deferred
        }
    }

    /// Tools that act on someone else's intents. They are privileged, so no
    /// autonomy mode runs them without a person.
    static let reviewingTools: Set<ToolIdentifier> = [
        Tools.ReviewIntent.identifier,
        Tools.ExecuteIntent.identifier,
    ]
}

private extension Intents.Executor {
    static func record(
        _ outcome: ToolInvocation.Outcome,
        tool: ToolIdentifier,
        attempt: Intents.Execution.Attempt
    ) -> Intents.Execution.Record {
        let name = tool.rawValue

        switch outcome {
        case .executed(let execution):
            let failed = execution.result.isError
            return .init(
                attemptID: attempt.id,
                outcome: failed ? .failed : .succeeded,
                summary: failed ? "\(name) reported an error." : "\(name) ran.",
                startedAt: attempt.startedAt,
                output: execution.result.output,
                error: execution.failure?.message
            )

        case .denied:
            return .init(
                attemptID: attempt.id,
                outcome: .failed,
                summary: "The current policy forbids \(name).",
                startedAt: attempt.startedAt
            )

        case .skipped, .interrupted:
            return .init(
                attemptID: attempt.id,
                outcome: .failed,
                summary: "\(name) did not run.",
                startedAt: attempt.startedAt
            )
        }
    }
}

/// The intent's review is the approval; this only carries it into the
/// executor.
private struct ReviewedApproval: ToolApprovalHandler {
    func decide(
        on _: ToolPreflight,
        requirement _: ApprovalRequirement
    ) async throws -> ApprovalDecision {
        .approved
    }
}
