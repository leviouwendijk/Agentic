import Agentic
import Primitives
import Schema
import Macros

public extension Sessions.Tools {
    @Tool("read")
    struct Read: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            public let sessionID: String
            public let includeInspection: Bool

            public init(
                sessionID: String,
                includeInspection: Bool = true
            ) {
                self.sessionID = sessionID
                self.includeInspection = includeInspection
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let summary: Sessions.Summary
            public let inspection: Sessions.Inspection?

            public init(
                summary: Sessions.Summary,
                inspection: Sessions.Inspection? = nil
            ) {
                self.summary = summary
                self.inspection = inspection
            }
        }

        public static let purpose = "Read Agentic session metadata and lightweight inspection counts."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func preflight(
            _ input: Input,
            in _: CapabilityContext
        ) async throws -> ToolPreflight {
            .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Read Agentic session \(input.sessionID).",
                sideEffects: []
            )
        }

        public func call(
            _ input: Input,
            in context: CapabilityContext
        ) async throws -> Output {
            let catalog = try context.require((any Sessions.CatalogReading).self)

            return Output(
                summary: try await catalog.session(
                    id: input.sessionID
                ),
                inspection: input.includeInspection
                    ? try await catalog.inspection(
                        sessionID: input.sessionID
                    )
                    : nil
            )
        }
    }
}
