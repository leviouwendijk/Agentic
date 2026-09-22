import Agentic
import Workspace
import Foundation
import Primitives

public extension Standard.Tools {
    struct AgentAdvisor: Tool {
        public typealias Input = AgentAdvisorInput
        public typealias Output = AgentAdvisorOutput

        public static let identifier = AgentAdvisorDefaults.identifier
        public static let description = "Ask the configured advisor model for bounded, advisory reasoning. The advisor receives no tools and cannot authorize actions."
        public static let risk: ActionRisk = .observe
        public static let definition = ToolDefinition(
            identifier: identifier,
            purpose: description,
            risk: risk
        )

        public var modelInvoker: any AgentModelInvoking
        public var configuration: AgentAdvisorConfiguration

        public init(
            modelInvoker: any AgentModelInvoking,
            configuration: AgentAdvisorConfiguration = .init()
        ) {
            self.modelInvoker = modelInvoker
            self.configuration = configuration
        }

        public var identifier: ToolIdentifier {
            configuration.identifier
        }

        public var description: String {
            "Ask the configured advisor model for bounded, advisory reasoning. The advisor receives no tools and cannot authorize actions."
        }

        public var risk: ActionRisk {
            .observe
        }

        public func preflight(
            _ input: Input,
            workspace _: WorkspaceContext?
        ) async throws -> ToolPreflight {
            ToolPreflight(
                tool: Self.definition.identifier,
                risk: Self.definition.risk,
                summary: """
                Ask an advisor model using route purpose '\(configuration.modelSelection.purpose.rawValue)'.

                The advisor call receives bounded text context only.
                No tools are exposed to the advisor model.
                """,
                sideEffects: [
                    "model_call",
                    "route:\(configuration.modelSelection.purpose.rawValue)",
                ]
            )
        }

        public func call(
            _ input: Input,
            workspace _: WorkspaceContext?
        ) async throws -> Output {

            let prompt = try Self.normalizedPrompt(
                input.prompt
            )

            var metadata: [String: String] = [:]

            metadata["tool"] = Self.definition.identifier.rawValue
            metadata["route"] = configuration.modelSelection.purpose.rawValue

            let request = AgentRequest(
                messages: [
                    .init(
                        role: .system,
                        text: configuration.systemPrompt
                    ),
                    .init(
                        role: .user,
                        text: Self.userPrompt(
                            input: input,
                            prompt: prompt
                        )
                    ),
                ],
                tools: [],
                generationConfiguration: .init(
                    maxOutputTokens: configuration.maxOutputTokens,
                    temperature: configuration.temperature
                ),
                metadata: metadata
            )

            let result = try await modelInvoker.buffered(
                AgentModelInvocation(
                    request: request,
                    selection: configuration.modelSelection,
                    context: .default,
                    metadata: metadata
                )
            )
            let route = result.route.route

            let output = AgentAdvisorOutput(
                routePurpose: route.purpose.rawValue,
                profile: route.profile.identifier.rawValue,
                gateway: route.profile.gatewayIdentifier.rawValue,
                model: route.profile.model,
                diagnostics: result.route.diagnostics,
                advice: result.response.message.content.text
            )

            return output
        }
    }
}

private extension Standard.Tools.AgentAdvisor {
    static func normalizedPrompt(
        _ value: String
    ) throws -> String {
        let prompt = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !prompt.isEmpty else {
            throw AgentAdvisorError.emptyPrompt
        }

        return prompt
    }

    static func normalizedOptionalText(
        _ value: String?
    ) -> String? {
        guard let value else {
            return nil
        }

        let trimmed = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return trimmed.isEmpty ? nil : trimmed
    }

    static func userPrompt(
        input: AgentAdvisorInput,
        prompt: String
    ) -> String {
        var sections: [String] = []

        if let context = normalizedOptionalText(
            input.context
        ) {
            sections.append(
                """
                Context:
                \(context)
                """
            )
        }

        sections.append(
            """
            Question:
            \(prompt)
            """
        )

        if let instruction = normalizedOptionalText(
            input.instruction
        ) {
            sections.append(
                """
                Instruction:
                \(instruction)
                """
            )
        }

        return sections.joined(
            separator: "\n\n"
        )
    }
}