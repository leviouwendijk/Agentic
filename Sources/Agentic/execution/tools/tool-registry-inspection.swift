import Schema

/// Immutable inspection snapshot for one ToolRegistry.
public struct ToolRegistryInspection:
    Sendable
{
    public let totalCount: Int
    public let tools: [ToolRegistryInspectionEntry]

    public init(
        totalCount: Int,
        tools: [ToolRegistryInspectionEntry]
    ) {
        self.totalCount = totalCount
        self.tools = tools
    }
}

/// Host-facing inspection facts captured from one registered tool.
public struct ToolRegistryInspectionEntry:
    Sendable
{
    public let identifier: ToolIdentifier
    public let description: String
    public let risk: ActionRisk
    public let isModelFacing: Bool
    public let semanticInputSchema: JSONSchema?
    public let modelFacingInputSchema: JSONSchema?

    public init(
        identifier: ToolIdentifier,
        description: String,
        risk: ActionRisk,
        isModelFacing: Bool,
        semanticInputSchema: JSONSchema?,
        modelFacingInputSchema: JSONSchema?
    ) {
        self.identifier = identifier
        self.description = description
        self.risk = risk
        self.isModelFacing = isModelFacing
        self.semanticInputSchema = semanticInputSchema
        self.modelFacingInputSchema = modelFacingInputSchema
    }

    public init(
        registered: ToolBinding
    ) {
        self.init(
            identifier: registered.definition.identifier,
            description: registered.definition.purpose,
            risk: registered.definition.risk,
            isModelFacing: registered.isModelFacing,
            semanticInputSchema:
                registered.semanticInputSchema,
            modelFacingInputSchema:
                registered.modelFacingInputSchema
        )
    }
}

public extension ToolRegistry {
    /// Inspect every currently registered tool without changing model exposure.
    func inspect()
        -> ToolRegistryInspection
    {
        .init(
            totalCount: count,
            tools: registeredTools.map { registered in
                ToolRegistryInspectionEntry(
                    registered: registered
                )
            }
        )
    }

    /// Inspect one exact registered tool identifier.
    func inspect(
        identifiedBy identifier: ToolIdentifier
    ) -> ToolRegistryInspectionEntry? {
        registeredTool(
            identifiedBy: identifier
        ).map { registered in
            ToolRegistryInspectionEntry(
                registered: registered
            )
        }
    }
}
