import Agentic
import Macros
import Schema

public extension Assertions.Tools {
    @Tool("assertions.define_set")
    struct DefineSet: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            public let id: String
            /// Must be absent for creation; exact current revision for modification.
            public let expectedRevision: Int?
            public let assertions: [Assertion]
            /// Freeze this revision so later revisions cannot weaken it.
            public let freeze: Bool?

            public init(
                id: String, expectedRevision: Int? = nil,
                assertions: [Assertion], freeze: Bool? = nil
            ) {
                self.id = id
                self.expectedRevision = expectedRevision
                self.assertions = assertions
                self.freeze = freeze
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let id: String
            public let revision: Int
            public let hash: String
            public let frozen: Bool

            public init(set: AssertionSet) {
                self.id = set.id
                self.revision = set.revision
                self.hash = set.hash
                self.frozen = set.frozen
            }
        }

        public static let purpose = "Create or revise a versioned assertion set using exact revision matching; optionally freeze the revision."
        public static let risk: ActionRisk = .boundedmutate
        public let runner: AssertionRunner
        public let store: AssertionSetStore

        public init(
            runner: AssertionRunner = .init(),
            store: AssertionSetStore = .shared
        ) {
            self.runner = runner
            self.store = store
        }

        public func preflight(_ input: Input, in _: ToolContext) async throws -> ToolPreflight {
            try runner.validate(input.assertions)
            return .init(
                tool: Self.identifier, risk: Self.risk,
                summary: "Define assertion set \(input.id) at expected revision \(String(describing: input.expectedRevision))",
                sideEffects: ["Changes assertion-set state"],
                policyChecks: ["exact_revision_required", "frozen_revisions_immutable"]
            )
        }

        public func call(_ input: Input, in _: ToolContext) async throws -> Output {
            try runner.validate(input.assertions)
            let set = try await store.define(
                id: input.id,
                expectedRevision: input.expectedRevision,
                assertions: input.assertions,
                freeze: input.freeze ?? false
            )
            return .init(set: set)
        }
    }
}
