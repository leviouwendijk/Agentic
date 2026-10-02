import Agentic
import Macros
import Schema
import Workspace

public extension LinkerCatalogFixture.Tools {
    @Tool("linker_fixture_alpha")
    struct Alpha: Tool {
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
            "Linker catalog alpha fixture."

        public static let risk: ActionRisk = .observe

        public init() {}

        public func call(
            _ input: Input,
            workspace: WorkspaceContext?
        ) async throws -> Output {
            _ = input
            _ = workspace

            return Output(
                value: "alpha"
            )
        }
    }
}
