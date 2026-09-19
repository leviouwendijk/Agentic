import AgenticRecovery
import Foundation

public struct NativeStructuredAdapter:
    InferenceAdapter,
    InferenceOutputRepairing,
    InferenceRecoveryClassifying,
    Sendable
{
    public let identifier: InferenceAdapterIdentifier

    public init(
        identifier: InferenceAdapterIdentifier = .native_structured
    ) {
        self.identifier = identifier
    }

    public func prepare<InferenceType: Inference>(
        _ inference: InferenceType.Type,
        input: InferenceType.Input,
        realization: InferenceRealizationConfiguration
    ) throws -> InferenceAdaptation {
        var messages: [AgentMessage] = []

        let instructions = renderInstructions(
            definition: inference.definition,
            realization: realization
        )

        if !instructions.isEmpty {
            messages.append(
                AgentMessage(
                    role: .system,
                    content: AgentContent(
                        text: instructions
                    )
                )
            )
        }

        for demonstration in realization.demonstrations {
            messages.append(
                AgentMessage(
                    role: .user,
                    content: AgentContent(
                        text: try renderJSON(
                            demonstration.input
                        )
                    )
                )
            )

            messages.append(
                AgentMessage(
                    role: .assistant,
                    content: AgentContent(
                        text: try renderJSON(
                            demonstration.output
                        )
                    )
                )
            )
        }

        messages.append(
            AgentMessage(
                role: .user,
                content: AgentContent(
                    text: try renderInput(
                        input
                    )
                )
            )
        )

        return InferenceAdaptation(
            request: AgentRequest(
                messages: messages,
                generationConfiguration: realization.generation,
                responseFormat: .jsonschema(
                    InferenceType.Output.jsonschema
                ),
                metadata: [
                    "inference.adapter": identifier.rawValue,
                    "inference.identifier": inference.definition.identifier.rawValue,
                    "inference.strategy": realization.strategy.rawValue,
                ]
            ),
            requirements: AgentModelRequirements(
                capabilities: [
                    .structured_output,
                ]
            )
        )
    }

    public func decode<InferenceType: Inference>(
        _ inference: InferenceType.Type,
        response: AgentResponse
    ) throws -> InferenceType.Output {
        let text = response.message.content.text
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !text.isEmpty else {
            throw NativeStructuredAdapterError.emptyResponse
        }

        do {
            return try JSONDecoder().decode(
                InferenceType.Output.self,
                from: Data(
                    text.utf8
                )
            )
        } catch {
            throw NativeStructuredAdapterError.invalidResponse(
                String(
                    describing: error
                )
            )
        }
    }

    public func repair<InferenceType: Inference>(
        _ inference: InferenceType.Type,
        input: InferenceType.Input,
        response: AgentResponse,
        error: any Error,
        realization: InferenceRealizationConfiguration
    ) throws -> InferenceAdaptation {
        var adaptation = try prepare(
            inference,
            input: input,
            realization: realization
        )

        adaptation.request.messages.append(
            response.message
        )
        adaptation.request.messages.append(
            AgentMessage(
                role: .user,
                content: AgentContent(
                    text: """
                    The previous response could not be decoded as the required structured output.
                    Return only a value that conforms to the required JSON schema.
                    Decode error: \(error.localizedDescription)
                    """
                )
            )
        )
        adaptation.request.metadata[
            "inference.recovery"
        ] = Recovery.Action.repair_output.rawValue

        return adaptation
    }

    public func incident(
        for error: any Error,
        stage: Recovery.Stage,
        inference: InferenceIdentifier,
        attemptIndex: Int,
        invocationIndex: Int
    ) -> Recovery.Incident? {
        guard stage == .decoding,
              error is NativeStructuredAdapterError
        else {
            return nil
        }

        return Recovery.Incident(
            kind: .structured_output_invalid,
            stage: .decoding,
            effectState: Recovery.EffectState.none,
            retrySafety: .safe,
            scope: .init(
                kind: .inference,
                identifier: inference.rawValue
            ),
            message: error.localizedDescription,
            metadata: [
                "adapter": identifier.rawValue,
                "attempt": String(attemptIndex),
                "invocation": String(invocationIndex),
            ]
        )
    }
}

private extension NativeStructuredAdapter {
    func renderInstructions(
        definition: InferenceDefinition,
        realization: InferenceRealizationConfiguration
    ) -> String {
        var sections: [String] = []

        let purpose = definition.purpose
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !purpose.isEmpty {
            sections.append(
                "Purpose:\n\(purpose)"
            )
        }

        let instructions = realization.instructions
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !instructions.isEmpty {
            sections.append(
                "Instructions:\n\(instructions)"
            )
        }

        return sections.joined(
            separator: "\n\n"
        )
    }

    func renderInput<Input: Encodable & Sendable>(
        _ input: Input
    ) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [
            .sortedKeys,
        ]

        return String(
            decoding: try encoder.encode(
                input
            ),
            as: UTF8.self
        )
    }

    func renderJSON<Value: Encodable>(
        _ value: Value
    ) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [
            .sortedKeys,
        ]

        return String(
            decoding: try encoder.encode(
                value
            ),
            as: UTF8.self
        )
    }
}
