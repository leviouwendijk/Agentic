import Agentic
import Macros
import Primitives
import Schema

public extension Intents.Tools {
    @Tool("list")
    struct ListIntents: Tool {
        /// List stored intents, newest first.
        @JSONSchema
        public struct Input: HashableSource {
            /// Only these statuses; all when omitted.
            public let statuses: [Intents.Intent.Status]?
            /// Only calls to this tool.
            public let tool: String?
            /// Include pending or approved intents past their expiry.
            public let includeExpired: Bool?
            /// Include other sessions' intents; defaults to the current session only.
            public let allSessions: Bool?
            public let limit: Int?

            public init(
                statuses: [Intents.Intent.Status]? = nil,
                tool: String? = nil,
                includeExpired: Bool? = nil,
                allSessions: Bool? = nil,
                limit: Int? = nil
            ) {
                self.statuses = statuses
                self.tool = tool
                self.includeExpired = includeExpired
                self.allSessions = allSessions
                self.limit = limit
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let intents: [Intents.Intent]
            public let total: Int

            public init(
                intents: [Intents.Intent],
                total: Int
            ) {
                self.intents = intents
                self.total = total
            }
        }

        public static let purpose = "List stored intents: tool calls an unattended run deferred for review."

        public static let risk: ActionRisk = .observe

        public init() {}

        public func preflight(
            _ input: Input,
            in _: ToolContext
        ) async throws -> ToolPreflight {
            .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "List intents.",
                sideEffects: []
            )
        }

        public func call(
            _ input: Input,
            in context: ToolContext
        ) async throws -> Output {
            let intents = try await context.intentManager().list(
                statuses: input.statuses ?? [],
                sessionID: input.allSessions == true
                    ? nil
                    : context.intentSessionID(),
                tool: input.tool.map(ToolIdentifier.init(rawValue:)),
                includeExpired: input.includeExpired ?? false
            )

            return Output(
                intents: Array(intents.prefix(max(0, input.limit ?? 50))),
                total: intents.count
            )
        }
    }

    @Tool("read")
    struct ReadIntent: Tool {
        /// Read one intent: its call, prepared operation, review and execution.
        @JSONSchema
        public struct Input: HashableSource {
            public let id: Intents.Intent.ID

            public init(
                id: Intents.Intent.ID
            ) {
                self.id = id
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let intent: Intents.Intent

            public init(
                intent: Intents.Intent
            ) {
                self.intent = intent
            }
        }

        public static let purpose = "Read one stored intent by id."

        public static let risk: ActionRisk = .observe

        public init() {}

        public func preflight(
            _ input: Input,
            in _: ToolContext
        ) async throws -> ToolPreflight {
            .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Read intent \(input.id).",
                sideEffects: []
            )
        }

        public func call(
            _ input: Input,
            in context: ToolContext
        ) async throws -> Output {
            Output(
                intent: try await context.intentManager().intent(input.id)
            )
        }
    }

    @Tool("review")
    struct ReviewIntent: Tool {
        /// Approve, deny, cancel or expire a pending or approved intent.
        @JSONSchema
        public struct Input: HashableSource {
            public let id: Intents.Intent.ID
            public let decision: Intents.Review.Decision
            /// Why; kept with the review.
            public let note: String?
            /// Who decided; kept with the review.
            public let reviewer: String?

            public init(
                id: Intents.Intent.ID,
                decision: Intents.Review.Decision,
                note: String? = nil,
                reviewer: String? = nil
            ) {
                self.id = id
                self.decision = decision
                self.note = note
                self.reviewer = reviewer
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let intent: Intents.Intent

            public init(
                intent: Intents.Intent
            ) {
                self.intent = intent
            }
        }

        public static let purpose = "Record a decision on a stored intent. Approving does not run it."

        /// Privileged: no autonomy mode reviews without a person.
        public static let risk: ActionRisk = .privileged

        public init() {}

        public func preflight(
            _ input: Input,
            in _: ToolContext
        ) async throws -> ToolPreflight {
            .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "\(input.decision.rawValue.capitalized) intent \(input.id).",
                estimates: .init(
                    write: .init(count: 1)
                ),
                sideEffects: [
                    "updates the intent file"
                ]
            )
        }

        public func call(
            _ input: Input,
            in context: ToolContext
        ) async throws -> Output {
            Output(
                intent: try await context.intentManager().review(
                    input.id,
                    decision: input.decision,
                    reviewer: input.reviewer,
                    note: input.note
                )
            )
        }
    }

    @Tool("execute")
    struct ExecuteIntent: Tool {
        /// Run an approved intent once, exactly as it was prepared.
        @JSONSchema
        public struct Input: HashableSource {
            public let id: Intents.Intent.ID

            public init(
                id: Intents.Intent.ID
            ) {
                self.id = id
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let intent: Intents.Intent

            public init(
                intent: Intents.Intent
            ) {
                self.intent = intent
            }
        }

        public static let purpose = "Run an approved intent's prepared call once and record the outcome."

        /// Privileged: no autonomy mode runs a deferred call without a person.
        public static let risk: ActionRisk = .privileged

        public init() {}

        public func preflight(
            _ input: Input,
            in context: ToolContext
        ) async throws -> ToolPreflight {
            let intent = try await context.intentManager().intent(input.id)
            return .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Run intent \(input.id): \(intent.preflight.summary)",
                sideEffects: intent.preflight.sideEffects
            )
        }

        public func call(
            _ input: Input,
            in context: ToolContext
        ) async throws -> Output {
            Output(
                intent: try await context.intentExecutor().execute(
                    input.id,
                    in: context
                )
            )
        }
    }
}
