import Agentic
import Macros
import Schema
import Workspace

public extension Harness.Tools {
    @Tool("inspect_exposure")
    struct InspectExposure: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            public let includeHidden: Bool?

            public init(
                includeHidden: Bool? = nil
            ) {
                self.includeHidden = includeHidden
            }

            public var resolvedIncludeHidden: Bool {
                includeHidden ?? false
            }
        }

        @JSONSchema
        public struct Entry: HashableProduct {
            public let kind: String
            public let identifier: String
            public let state: String

            public init(
                kind: String,
                identifier: String,
                state: String
            ) {
                self.kind = kind
                self.identifier = identifier
                self.state = state
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let selectedCount: Int
            public let exposedCount: Int
            public let hiddenCount: Int
            public let entries: [Entry]

            public init(
                selectedCount: Int,
                exposedCount: Int,
                hiddenCount: Int,
                entries: [Entry]
            ) {
                self.selectedCount = selectedCount
                self.exposedCount = exposedCount
                self.hiddenCount = hiddenCount
                self.entries = entries
            }
        }

        public protocol InspectionSource: Sendable {
            func inspect(
                _ input: Input
            ) async throws -> Output
        }

        public static let purpose =
            "Inspect the current Agentic agent capability exposure without changing it."

        public static let risk: ActionRisk = .observe

        public let source: any InspectionSource

        public init(
            source: any InspectionSource
        ) {
            self.source = source
        }

        public func preflight(
            _ input: Input,
            workspace _: WorkspaceContext?
        ) async throws -> ToolPreflight {
            _ = input

            return .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Inspect the current Agentic agent exposure.",
                sideEffects: []
            )
        }

        public func call(
            _ input: Input,
            workspace _: WorkspaceContext?
        ) async throws -> Output {
            try await source.inspect(
                input
            )
        }
    }
}
