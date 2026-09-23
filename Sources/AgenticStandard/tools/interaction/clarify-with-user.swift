import Agentic
import Workspace
import Macros
import Primitives
import Schema

public extension Standard.Tools {
    struct ClarifyWithUser: Tool {
        @JSONSchema
        public struct Input: Source, Hashable {
            public let prompt: String
            public let reason: String?
            public let requirement: UserInputRequirement?
            public let input: UserInputSpec
            public let presentation: UserInputPresentation?
            public let metadata: [String: String]

            public init(
                prompt: String,
                reason: String? = nil,
                requirement: UserInputRequirement? = nil,
                input: UserInputSpec = .text(
                    .init()
                ),
                presentation: UserInputPresentation? = nil,
                metadata: [String: String] = [:]
            ) {
                self.prompt = prompt
                self.reason = reason
                self.requirement = requirement
                self.input = input
                self.presentation = presentation
                self.metadata = metadata
            }

            public func request() throws -> UserInputRequest {
                try UserInputRequest(
                    .init(
                        prompt: prompt,
                        reason: reason,
                        requirement: requirement,
                        input: input,
                        presentation: presentation,
                        metadata: metadata
                    )
                )
            }
        }

        @JSONSchema
        public struct Output: Result, Hashable {
            public let kind: String
            public let request: UserInputRequest

            public init(
                kind: String = "pending_user_input",
                request: UserInputRequest
            ) {
                self.kind = kind
                self.request = request
            }
        }

        public static let identifier: ToolIdentifier = "clarify_with_user"

        public static let description =
            "Suspend the current agent run and ask the user for missing information needed to continue."

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

        public init() {}

        public func preflight(
            _ input: Input,
            workspace _: WorkspaceContext?
        ) async throws -> ToolPreflight {
            let request = try input.request()

            return .init(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: request.prompt,
                estimates: .init(bytes: 0),
                sideEffects: [
                    "suspends the current agent run",
                    "waits for typed user input before continuing",
                ]
            )
        }

        public func call(
            _ input: Input,
            workspace _: WorkspaceContext?
        ) async throws -> Output {
            .init(
                request: try input.request()
            )
        }
    }
}
