import Agentic
import Primitives
import Schema
import Macros

public extension Tasks.Tools {
    @Tool("task_record_attempt")
    struct RecordAttempt: Tool {
        /// Submit an assignee's report for a task; the task then awaits acceptance.
        @JSONSchema
        public struct Input: HashableSource {
            public let id: AgentTaskIdentifier
            public let owner: String?
            public let report: AgentTaskAttemptReport

            public init(
                id: AgentTaskIdentifier,
                owner: String? = nil,
                report: AgentTaskAttemptReport
            ) {
                self.id = id
                self.owner = owner
                self.report = report
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let task: AgentTask

            public init(
                task: AgentTask
            ) {
                self.task = task
            }
        }

        public static let purpose = "Submit the report of one attempt at a task. The task waits for task_accept or task_reject; recording never completes it."

        public static let risk: ActionRisk = .boundedmutate

        public init() {}

        public func preflight(
            _ input: Input,
            in _: ToolContext
        ) async throws -> ToolPreflight {
            .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Record an attempt for task \(input.id.rawValue).",
                estimates: .init(
                    write: .init(count: 1)
                ),
                sideEffects: [
                    "writes task file"
                ]
            )
        }

        public func call(
            _ input: Input,
            in context: ToolContext
        ) async throws -> Output {
            .init(
                task: try await context.taskManager().recordAttempt(
                    id: input.id,
                    owner: input.owner,
                    report: input.report
                )
            )
        }
    }

    @Tool("task_accept")
    struct AcceptTask: Tool {
        /// Accept a submitted attempt, complete the task, and unblock dependents.
        @JSONSchema
        public struct Input: HashableSource {
            public let id: AgentTaskIdentifier
            public let note: String?

            public init(
                id: AgentTaskIdentifier,
                note: String? = nil
            ) {
                self.id = id
                self.note = note
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let task: AgentTask

            public init(
                task: AgentTask
            ) {
                self.task = task
            }
        }

        public static let purpose = "Accept a task's submitted attempt against its acceptance conditions, completing it and unblocking dependents."

        public static let risk: ActionRisk = .boundedmutate

        public init() {}

        public func preflight(
            _ input: Input,
            in _: ToolContext
        ) async throws -> ToolPreflight {
            .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Accept the submitted attempt for task \(input.id.rawValue).",
                estimates: .init(
                    write: .init(count: 2)
                ),
                sideEffects: [
                    "writes task file",
                    "may unblock dependent tasks"
                ]
            )
        }

        public func call(
            _ input: Input,
            in context: ToolContext
        ) async throws -> Output {
            .init(
                task: try await context.taskManager().accept(
                    id: input.id,
                    note: input.note
                )
            )
        }
    }

    @Tool("task_reject")
    struct RejectTask: Tool {
        /// Reject a submitted attempt and return the task to pending.
        @JSONSchema
        public struct Input: HashableSource {
            public let id: AgentTaskIdentifier
            public let note: String

            public init(
                id: AgentTaskIdentifier,
                note: String
            ) {
                self.id = id
                self.note = note
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let task: AgentTask

            public init(
                task: AgentTask
            ) {
                self.task = task
            }
        }

        public static let purpose = "Reject a task's submitted attempt with the reason, returning the task to pending for a bounded retry."

        public static let risk: ActionRisk = .boundedmutate

        public init() {}

        public func preflight(
            _ input: Input,
            in _: ToolContext
        ) async throws -> ToolPreflight {
            .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Reject the submitted attempt for task \(input.id.rawValue).",
                estimates: .init(
                    write: .init(count: 1)
                ),
                sideEffects: [
                    "writes task file"
                ]
            )
        }

        public func call(
            _ input: Input,
            in context: ToolContext
        ) async throws -> Output {
            .init(
                task: try await context.taskManager().reject(
                    id: input.id,
                    note: input.note
                )
            )
        }
    }

    @Tool("task_fail")
    struct FailTask: Tool {
        /// Mark a submitted attempt, and its task, failed.
        @JSONSchema
        public struct Input: HashableSource {
            public let id: AgentTaskIdentifier
            public let note: String

            public init(
                id: AgentTaskIdentifier,
                note: String
            ) {
                self.id = id
                self.note = note
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let task: AgentTask

            public init(
                task: AgentTask
            ) {
                self.task = task
            }
        }

        public static let purpose = "Fail a task whose submitted attempt cannot be retried within its contract."

        public static let risk: ActionRisk = .boundedmutate

        public init() {}

        public func preflight(
            _ input: Input,
            in _: ToolContext
        ) async throws -> ToolPreflight {
            .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Fail task \(input.id.rawValue).",
                estimates: .init(
                    write: .init(count: 1)
                ),
                sideEffects: [
                    "writes task file"
                ]
            )
        }

        public func call(
            _ input: Input,
            in context: ToolContext
        ) async throws -> Output {
            .init(
                task: try await context.taskManager().fail(
                    id: input.id,
                    note: input.note
                )
            )
        }
    }
}
