import Agentic
import Primitives
import Schema
import Macros

public extension Tasks.Tools {
    @Tool("create")
    struct CreateTask: Tool {
        /// Create a new agent task.
        @JSONSchema
        public struct Input: HashableSource {
            public let subject: String
            public let description: String?
            public let blockedBy: [AgentTaskIdentifier]?
            public let owner: String?
            public let contract: AgentTaskContract?
            public let metadata: [String: String]?

            public init(
                subject: String,
                description: String? = nil,
                blockedBy: [AgentTaskIdentifier]? = nil,
                owner: String? = nil,
                contract: AgentTaskContract? = nil,
                metadata: [String: String]? = nil
            ) {
                self.subject = subject
                self.description = description
                self.blockedBy = blockedBy
                self.owner = owner
                self.contract = contract
                self.metadata = metadata
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

        public static let purpose = "Create a durable Agentic task, optionally carrying a typed assignment contract."

        public static let risk: ActionRisk = .boundedmutate

        public init() {}

        public func preflight(
            _ input: Input,
            in _: CapabilityContext
        ) async throws -> ToolPreflight {
            .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Create durable task: \(input.subject)",
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
            in context: CapabilityContext
        ) async throws -> Output {
            let task = try await context.taskManager().create(
                subject: input.subject,
                description: input.description ?? "",
                blockedBy: input.blockedBy ?? [],
                owner: input.owner,
                sessionID: context.taskSessionID(),
                contract: input.contract,
                metadata: input.metadata ?? [:]
            )

            return Output(
                task: task
            )
        }
    }

    @Tool("update")
    struct UpdateTask: Tool {
        /// Update mutable fields on an existing agent task.
        @JSONSchema
        public struct Input: HashableSource {
            public let id: AgentTaskIdentifier
            public let subject: String?
            public let description: String?
            public let status: AgentTaskStatus?
            public let owner: String?
            public let addBlockedBy: [AgentTaskIdentifier]?
            public let removeBlockedBy: [AgentTaskIdentifier]?
            public let metadataPatch: [String: String]?

            public init(
                id: AgentTaskIdentifier,
                subject: String? = nil,
                description: String? = nil,
                status: AgentTaskStatus? = nil,
                owner: String? = nil,
                addBlockedBy: [AgentTaskIdentifier]? = nil,
                removeBlockedBy: [AgentTaskIdentifier]? = nil,
                metadataPatch: [String: String]? = nil
            ) {
                self.id = id
                self.subject = subject
                self.description = description
                self.status = status
                self.owner = owner
                self.addBlockedBy = addBlockedBy
                self.removeBlockedBy = removeBlockedBy
                self.metadataPatch = metadataPatch
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

        public static let purpose = "Update a durable Agentic task."

        public static let risk: ActionRisk = .boundedmutate

        public init() {}

        public func preflight(
            _ input: Input,
            in _: CapabilityContext
        ) async throws -> ToolPreflight {
            .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Update durable task \(input.id.rawValue).",
                estimates: .init(
                    write: .init(
                        count: input.status == .completed ? 2 : 1
                    )
                ),
                sideEffects: [
                    "writes task file",
                    "may clear dependency from blocked tasks"
                ]
            )
        }

        public func call(
            _ input: Input,
            in context: CapabilityContext
        ) async throws -> Output {
            let task = try await context.taskManager().update(
                id: input.id,
                subject: input.subject,
                description: input.description,
                status: input.status,
                owner: input.owner,
                addBlockedBy: input.addBlockedBy ?? [],
                removeBlockedBy: input.removeBlockedBy ?? [],
                metadataPatch: input.metadataPatch ?? [:]
            )

            return Output(
                task: task
            )
        }
    }

    @Tool("list")
    struct ListTasks: Tool {
        /// List agent tasks with optional status, owner, readiness, and completion filters.
        @JSONSchema
        public struct Input: HashableSource {
            public let statuses: [AgentTaskStatus]?
            public let owner: String?
            public let readyOnly: Bool?
            public let includeCompleted: Bool?
            /// Include tasks from other sessions; defaults to the current session only.
            public let allSessions: Bool?

            public init(
                statuses: [AgentTaskStatus]? = nil,
                owner: String? = nil,
                readyOnly: Bool? = nil,
                includeCompleted: Bool? = nil,
                allSessions: Bool? = nil
            ) {
                self.statuses = statuses
                self.owner = owner
                self.readyOnly = readyOnly
                self.includeCompleted = includeCompleted
                self.allSessions = allSessions
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let tasks: [AgentTask]
            public let count: Int

            public init(
                tasks: [AgentTask]
            ) {
                self.tasks = tasks
                self.count = tasks.count
            }
        }

        public static let purpose = "List durable Agentic tasks, scoped to the current session by default."

        public static let risk: ActionRisk = .observe

        public init() {}

        public func preflight(
            _ input: Input,
            in _: CapabilityContext
        ) async throws -> ToolPreflight {
            .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "List durable tasks.",
                sideEffects: []
            )
        }

        public func call(
            _ input: Input,
            in context: CapabilityContext
        ) async throws -> Output {
            let tasks = try await context.taskManager().list(
                statuses: input.statuses ?? [],
                owner: input.owner,
                sessionID: input.allSessions == true
                    ? nil
                    : context.taskSessionID(),
                readyOnly: input.readyOnly ?? false,
                includeCompleted: input.includeCompleted ?? true
            )

            return Output(
                tasks: tasks
            )
        }
    }

    @Tool("get")
    struct GetTask: Tool {
        /// Read one agent task by identifier.
        @JSONSchema
        public struct Input: HashableSource {
            public let id: AgentTaskIdentifier

            public init(
                id: AgentTaskIdentifier
            ) {
                self.id = id
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

        public static let purpose = "Read a durable Agentic task, including its contract and attempts."

        public static let risk: ActionRisk = .observe

        public init() {}

        public func preflight(
            _ input: Input,
            in _: CapabilityContext
        ) async throws -> ToolPreflight {
            .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Read durable task \(input.id.rawValue).",
                sideEffects: []
            )
        }

        public func call(
            _ input: Input,
            in context: CapabilityContext
        ) async throws -> Output {
            let task = try await context.taskManager().get(
                input.id
            )

            return Output(
                task: task
            )
        }
    }

    @Tool("claim")
    struct ClaimTask: Tool {
        /// Claim an agent task for an owner.
        @JSONSchema
        public struct Input: HashableSource {
            public let id: AgentTaskIdentifier
            public let owner: String

            public init(
                id: AgentTaskIdentifier,
                owner: String
            ) {
                self.id = id
                self.owner = owner
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

        public static let purpose = "Claim a durable Agentic task for an owner."

        public static let risk: ActionRisk = .boundedmutate

        public init() {}

        public func preflight(
            _ input: Input,
            in _: CapabilityContext
        ) async throws -> ToolPreflight {
            .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Claim task \(input.id.rawValue) for \(input.owner).",
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
            in context: CapabilityContext
        ) async throws -> Output {
            let task = try await context.taskManager().claim(
                id: input.id,
                owner: input.owner
            )

            return Output(
                task: task
            )
        }
    }

    @Tool("complete")
    struct CompleteTask: Tool {
        /// Mark an agent task complete.
        @JSONSchema
        public struct Input: HashableSource {
            public let id: AgentTaskIdentifier

            public init(
                id: AgentTaskIdentifier
            ) {
                self.id = id
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

        public static let purpose = "Complete a durable Agentic task that needs no attempt review, and unblock dependents. Use tasks_tool_accept for submitted attempts."

        public static let risk: ActionRisk = .boundedmutate

        public init() {}

        public func preflight(
            _ input: Input,
            in _: CapabilityContext
        ) async throws -> ToolPreflight {
            .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Complete task \(input.id.rawValue) and clear dependency edges.",
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
            in context: CapabilityContext
        ) async throws -> Output {
            let task = try await context.taskManager().complete(
                id: input.id
            )

            return Output(
                task: task
            )
        }
    }
}
