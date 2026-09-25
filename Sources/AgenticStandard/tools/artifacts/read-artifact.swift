import Agentic
import Workspace
import Primitives
import Schema
import Macros

public extension Standard.Tools {
    @Tool
    struct ReadArtifact: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            /// Exact artifact identifier to read.
            public let id: String
            /// Whether to include artifact content. Defaults to true when omitted.
            public let includeContent: Bool?
            /// Optional maximum number of content characters to return.
            public let maxCharacters: Int?

            public init(
                id: String,
                includeContent: Bool? = nil,
                maxCharacters: Int? = nil
            ) {
                self.id = id
                self.includeContent = includeContent
                self.maxCharacters = maxCharacters
            }

            public var shouldIncludeContent: Bool {
                includeContent ?? true
            }

            public var resolvedMaxCharacters: Int? {
                guard let maxCharacters else {
                    return nil
                }

                return max(
                    0,
                    maxCharacters
                )
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let artifact: AgentArtifact
            public let content: String?
            public let truncated: Bool

            public init(
                artifact: AgentArtifact,
                content: String?,
                truncated: Bool
            ) {
                self.artifact = artifact
                self.content = content
                self.truncated = truncated
            }
        }

    public static let purpose = "Read a durable artifact emitted for the current Agentic session."

    public static let risk: ActionRisk = .observe



    public let store: any AgentArtifactStore

    public init(
        store: any AgentArtifactStore
    ) {
        self.store = store
    }

    public func preflight(
        _ input: Input,
        workspace _: WorkspaceContext?
    ) async throws -> ToolPreflight {

        return .init(
            tool: Self.definition.identifier,
            risk: Self.definition.risk,
            summary: "Read session artifact \(input.id).",
            sideEffects: []
        )
    }

    public func call(
        _ input: Input,
        workspace _: WorkspaceContext?
    ) async throws -> Output {

        guard let record = try await store.load(
            id: input.id
        ) else {
            throw AgentArtifactError.artifactNotFound(
                input.id
            )
        }

        let renderedContent: String?
        let truncated: Bool

        if input.shouldIncludeContent {
            let limited = limitedContent(
                record.content,
                maxCharacters: input.resolvedMaxCharacters
            )

            renderedContent = limited.content
            truncated = limited.truncated
        } else {
            renderedContent = nil
            truncated = false
        }

        return Output(
                artifact: record.artifact,
                content: renderedContent,
                truncated: truncated
            )
    }
    }
}

private extension Standard.Tools.ReadArtifact {
    func limitedContent(
        _ content: String,
        maxCharacters: Int?
    ) -> (content: String, truncated: Bool) {
        guard let maxCharacters else {
            return (
                content,
                false
            )
        }

        guard content.count > maxCharacters else {
            return (
                content,
                false
            )
        }

        return (
            String(
                content.prefix(
                    maxCharacters
                )
            ),
            true
        )
    }
}
