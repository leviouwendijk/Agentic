import Agentic
import Workspace
import Primitives
import Schema
import Macros

public extension Standard.Tools {
    struct LoadSkill: Tool {
        @JSONSchema
        public struct Input: Source, Hashable {
            /// Optional exact skill identifier. Supply id or name.
            public let id: String?

            /// Optional exact skill name. Supply name or id.
            public let name: String?

            /// Whether to include skill metadata in the returned result.
            public let includeMetadata: Bool?

            public init(
                id: String? = nil,
                name: String? = nil,
                includeMetadata: Bool? = nil
            ) {
                self.id = id
                self.name = name
                self.includeMetadata = includeMetadata
            }
        }

        @JSONSchema
        public struct Output: Result, Hashable {
            public let id: String
            public let name: String
            public let summary: String
            public let content: String
            public let metadata: AgentSkillMetadata?

            public init(
                id: String,
                name: String,
                summary: String,
                content: String,
                metadata: AgentSkillMetadata?
            ) {
                self.id = id
                self.name = name
                self.summary = summary
                self.content = content
                self.metadata = metadata
            }
        }

        public static let identifier: ToolIdentifier = "load_skill"

        public static let description =
            "Load the full instructions for one available skill by id or name."

        public static let risk: ActionRisk = .observe

        public static let definition = ToolDefinition(
            identifier: identifier,
            purpose: description,
            risk: risk
        )

        public var identifier: ToolIdentifier {
            Self.identifier
        }

        public var description: String {
            Self.description
        }

        public var risk: ActionRisk {
            Self.risk
        }

        public let registry: SkillRegistry

        public init(
            registry: SkillRegistry
        ) {
            self.registry = registry
        }

        public func preflight(
            _ input: Input,
            workspace _: WorkspaceContext?
        ) async throws -> ToolPreflight {
            let lookup = try lookupValue(
                from: input
            )

            return .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: "Load skill '\(lookup)'.",
                sideEffects: Self.definition.risk.defaultSideEffects
            )
        }

        public func call(
            _ input: Input,
            workspace _: WorkspaceContext?
        ) async throws -> Output {
            let lookup = try lookupValue(
                from: input
            )
            let skill = try registry.requireSkill(
                matching: lookup
            )

            return Output(
                id: skill.identifier.rawValue,
                name: skill.name,
                summary: skill.summary,
                content: skill.contextText,
                metadata: input.includeMetadata == true
                    ? skill.metadata
                    : nil
            )
        }
    }
}

private extension Standard.Tools.LoadSkill {
    func lookupValue(
        from input: Input
    ) throws -> String {
        let value = input.id ?? input.name
        let trimmed = value?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard let trimmed,
              !trimmed.isEmpty
        else {
            throw SkillError.missingSkillIdentifier
        }

        return trimmed
    }
}
