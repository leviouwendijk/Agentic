import Agentic
import Macros
import Primitives
import Schema

public extension Standard.Tools {
    @Tool
    struct ClarifyWithUser: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            /// Question or instruction shown to the user.
            public let prompt: String

            /// Optional explanation of why user input is needed.
            public let reason: String?

            /// Whether the user must answer or may skip the request.
            public let requirement: UserInputRequirement?

            /// The semantic input shape the user should answer. This determines `UserInputSpec.kind`; `presentation.preferredControl` only controls rendering.
            public let input: UserInputSpec

            /// Optional rendering hints. Presentation controls such as `text_field` are not valid `input.kind` values.
            public let presentation: UserInputPresentation?

            /// Additional application-defined metadata.
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
        public struct Output: HashableResult {
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

        public static let purpose =
            "Suspend the current agent run and ask the user for missing information needed to continue."

        public static let risk: ActionRisk = .observe



        public init() {}

        public func preflight(
            _ input: Input,
            in _: ToolContext
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
            in _: ToolContext
        ) async throws -> Output {
            .init(
                request: try input.request()
            )
        }
    }
}
