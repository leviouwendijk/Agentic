import Agentic
import Macros
import Schema

public extension Assertions.Tools {
    @Tool("assertions.evaluate_set")
    struct EvaluateSet: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            public let id: String
            /// Expected exact latest revision; this tool must not silently substitute a newer one.
            public let revision: Int
            public let hash: String?

            public init(id: String, revision: Int, hash: String? = nil) {
                self.id = id
                self.revision = revision
                self.hash = hash
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let id: String
            public let revision: Int
            public let hash: String
            public let report: AssertionReport

            public init(id: String, revision: Int, hash: String, report: AssertionReport) {
                self.id = id
                self.revision = revision
                self.hash = hash
                self.report = report
            }
        }

        public static let purpose = "Re-evaluate a pinned revision of an existing assertion set and report individual results."
        public static let risk: ActionRisk = .observe
        public let runner: AssertionRunner
        public let store: AssertionSetStore

        public init(runner: AssertionRunner = .init(), store: AssertionSetStore = .shared) {
            self.runner = runner
            self.store = store
        }

        public func preflight(_ input: Input, in _: ToolContext) async throws -> ToolPreflight {
            guard let set = try await store.load(id: input.id, revision: input.revision) else {
                throw AssertionSetStoreError.missing
            }
            try runner.validate(set.assertions)
            let paths = set.assertions.filter { $0.subject.kind == "workspace_file" }
                .map { $0.subject.value }
            return .init(
                tool: Self.identifier,
                risk: paths.isEmpty ? .observe : .privileged,
                summary: "Evaluate assertion set \(input.id) revision \(input.revision)",
                access: .init(
                    targets: paths,
                    roots: paths.isEmpty ? [] : ["project"],
                    capabilities: paths.isEmpty ? [] : [.read]
                ),
                sideEffects: []
            )
        }

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            guard let set = try await store.load(id: input.id, revision: input.revision) else {
                throw AssertionSetStoreError.missing
            }
            guard input.hash == nil || input.hash == set.hash else {
                throw AssertionSetStoreError.expected_revision_mismatch
            }
            let report = try await runner.run(set.assertions, in: context)
            return .init(id: set.id, revision: set.revision, hash: set.hash, report: report)
        }
    }
}
