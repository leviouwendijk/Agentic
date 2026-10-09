import Schema

/// Model-facing registration state captured when a canonical Tool enters ToolRegistry.
///
/// The authored semantic `T.Input` JSONSchema remains semantic registration data.
/// Model-facing projection wraps it in the generic `{ arguments, execution }` invocation
/// envelope; Workspace later decides whether a requested execution target is permitted.
public enum ToolModelContract: Sendable {
    case modelFacing(
        inputSchema: JSONSchema
    )

    case hostOnly

    public var semanticInputSchema: JSONSchema? {
        switch self {
        case .modelFacing(let inputSchema):
            inputSchema

        case .hostOnly:
            nil
        }
    }

    public var isModelFacing: Bool {
        switch self {
        case .modelFacing:
            true

        case .hostOnly:
            false
        }
    }

    public var modelFacingInputSchema: JSONSchema? {
        guard let semantic = semanticInputSchema else {
            return nil
        }

        return CapabilityModelInputSchema.envelope(
            semanticInput: semantic,
            execution: ToolInvocation.Execution.jsonschema
        )
    }
}
