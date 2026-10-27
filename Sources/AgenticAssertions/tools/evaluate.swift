import Agentic
import Macros
import Schema

public extension Assertions.Tools {
    @Tool("assertions.evaluate")
    struct Evaluate: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            public let assertions: [Assertion]
            public init(assertions: [Assertion]) { self.assertions = assertions }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let report: AssertionReport
            public init(report: AssertionReport) { self.report = report }
        }

        public static let purpose = "Evaluate declarative assertions and return evidence without treating assertion failure as tool failure."
        public static let risk: ActionRisk = .observe
        public let runner: AssertionRunner

        public init(runner: AssertionRunner = .init()) {
            self.runner = runner
        }

        public func preflight(_ input: Input, in _: ToolContext) async throws -> ToolPreflight {
            try runner.validate(input.assertions)
            let paths = input.assertions.filter { $0.subject.kind == "workspace_file" }
                .map { $0.subject.value }
            return .init(
                tool: Self.identifier,
                risk: paths.isEmpty ? .observe : .privileged,
                summary: "Evaluate \(input.assertions.count) assertions",
                access: .init(
                    targets: paths,
                    roots: paths.isEmpty ? [] : ["project"],
                    capabilities: paths.isEmpty ? [] : [.read]
                ),
                sideEffects: []
            )
        }

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            .init(report: try await runner.run(input.assertions, in: context))
        }
    }
}
