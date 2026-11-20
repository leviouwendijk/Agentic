import Agentic
import Macros
import Schema

public extension Assertions.Tools {
    @Tool("assertions.inspect_set")
    struct InspectSet: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            public let id: String
            public init(id: String) { self.id = id }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let id: String
            public let revision: Int
            public let hash: String
            public let frozen: Bool
            public let assertions: [Assertion]

            public init(set: AssertionSet) {
                self.id = set.id
                self.revision = set.revision
                self.hash = set.hash
                self.frozen = set.frozen
                self.assertions = set.assertions
            }
        }

        public static let purpose = "Inspect current assertion-set definitions and immutable revision metadata without executing them."
        public static let risk: ActionRisk = .observe
        public let store: AssertionSetStore

        public init(store: AssertionSetStore = .shared) {
            self.store = store
        }

        public func call(_ input: Input, in _: ToolContext) async throws -> Output {
            guard let set = try await store.load(id: input.id) else {
                throw AssertionSetStoreError.missing
            }
            return .init(set: set)
        }
    }
}
