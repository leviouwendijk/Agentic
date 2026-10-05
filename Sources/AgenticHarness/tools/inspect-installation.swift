import Agentic
import Macros
import Schema

public extension Harness.Tools {
    @Tool("inspect_installation")
    struct InspectInstallation: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            public let kinds: [String]
            public let identifier: String?

            public init(
                kinds: [String] = [],
                identifier: String? = nil
            ) {
                self.kinds = kinds
                self.identifier = identifier
            }
        }

        @JSONSchema
        public struct Entry: HashableProduct {
            public let kind: String
            public let identifier: String
            public let namespace: String?
            public let executable: Bool
            public let modelFacing: Bool?

            public init(
                kind: String,
                identifier: String,
                namespace: String? = nil,
                executable: Bool,
                modelFacing: Bool? = nil
            ) {
                self.kind = kind
                self.identifier = identifier
                self.namespace = namespace
                self.executable = executable
                self.modelFacing = modelFacing
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let totalCount: Int
            public let returnedCount: Int
            public let entries: [Entry]

            public init(
                totalCount: Int,
                returnedCount: Int,
                entries: [Entry]
            ) {
                self.totalCount = totalCount
                self.returnedCount = returnedCount
                self.entries = entries
            }
        }

        public protocol InspectionSource: Sendable {
            func inspect(
                _ input: Input
            ) async throws -> Output
        }

        public static let purpose =
            "Inspect the capabilities installed in the current Agentic application, including semantic identity and executable availability."

        public static let risk: ActionRisk = .observe

        public let source: any InspectionSource

        public init(
            source: any InspectionSource
        ) {
            self.source = source
        }

        public func preflight(
            _ input: Input,
            in _: ToolContext
        ) async throws -> ToolPreflight {
            _ = input

            return .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Inspect the current Agentic application installation.",
                sideEffects: []
            )
        }

        public func call(
            _ input: Input,
            in _: ToolContext
        ) async throws -> Output {
            try await source.inspect(
                input
            )
        }
    }
}
