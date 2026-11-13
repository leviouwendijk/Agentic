import Agentic
import Primitives
import Schema
import Macros

public extension Standard.Tools {
    @Tool
    struct ListArtifacts: Tool {
        public struct Input: HashableSource, CodableInvariant {
            @JSONSchema
            public struct Raw: HashableSource {
                /// Artifact kinds to include. An empty array includes every kind.
                public var kinds: [AgentArtifactKind]
                /// Whether to list newest artifacts first. Defaults to true when omitted.
                public var latestFirst: Bool?
                /// Optional maximum number of artifacts to return.
                public var limit: Int?

                public init(
                    kinds: [AgentArtifactKind] = [],
                    latestFirst: Bool? = nil,
                    limit: Int? = nil
                ) {
                    self.kinds = kinds
                    self.latestFirst = latestFirst
                    self.limit = limit
                }
            }

            public let kinds: [AgentArtifactKind]
            public let latestFirst: Bool
            /// Never negative; nil means unlimited.
            public let limit: Int?

            public init(_ raw: Raw) {
                self.kinds = raw.kinds
                self.latestFirst = raw.latestFirst ?? true
                self.limit = raw.limit.map { max(0, $0) }
            }

            public init(
                kinds: [AgentArtifactKind] = [],
                latestFirst: Bool? = nil,
                limit: Int? = nil
            ) {
                self.init(
                    Raw(
                        kinds: kinds,
                        latestFirst: latestFirst,
                        limit: limit
                    )
                )
            }

            public var raw: Raw {
                Raw(
                    kinds: kinds,
                    latestFirst: latestFirst,
                    limit: limit
                )
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let artifacts: [AgentArtifact]
            public let count: Int

            public init(
                artifacts: [AgentArtifact]
            ) {
                self.artifacts = artifacts
                self.count = artifacts.count
            }
        }

    public static let purpose = "List durable artifacts emitted for the current Agentic session."

    public static let risk: ActionRisk = .observe



    public let store: any AgentArtifactStore

    public init(
        store: any AgentArtifactStore
    ) {
        self.store = store
    }

    public func preflight(
        _ input: Input,
        in _: ToolContext
    ) async throws -> ToolPreflight {

        return .init(
            tool: Self.definition.identifier,
            risk: Self.definition.risk,
            summary: summary(
                for: input
            ),
            sideEffects: []
        )
    }

    public func call(
        _ input: Input,
        in _: ToolContext
    ) async throws -> Output {

        let artifacts = try await store.list(
            kinds: input.kinds,
            latestFirst: input.latestFirst,
            limit: input.limit
        )

        return Output(
                artifacts: artifacts
            )
    }
    }
}

private extension Standard.Tools.ListArtifacts {
    func summary(
        for input: Input
    ) -> String {
        guard !input.kinds.isEmpty else {
            return "List session artifacts"
        }

        return "List session artifacts filtered to \(input.kinds.map(\.rawValue).joined(separator: ", "))"
    }
}
