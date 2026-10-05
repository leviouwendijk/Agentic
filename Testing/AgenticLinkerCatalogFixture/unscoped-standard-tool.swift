import Agentic
import Macros
import Schema

@Tool("unscoped_standard_collision")
public struct Standard: Tool {
    @JSONSchema
    public struct Input: HashableSource {
        public init() {}
    }

    @JSONSchema
    public struct Output: HashableResult {
        public let value: String

        public init(
            value: String
        ) {
            self.value = value
        }
    }

    public static let purpose =
        "Proves top-level semantic declarations remain unscoped and cannot collide with a same-named Domain."

    public static let risk: ActionRisk = .observe

    public init() {}

    public func call(
        _ input: Input,
        in context: ToolContext
    ) async throws -> Output {
        _ = input
        _ = context

        return Output(
            value: "unscoped"
        )
    }
}
