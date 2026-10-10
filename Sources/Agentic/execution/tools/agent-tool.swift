import Primitives
import Schema

// Agentic.Tool is the canonical authored tool contract.
//
// AgenticExecution adds registration/type-erasure/runtime behavior around Tool;
// it must not define a second authored tool protocol.
public extension Tool {
    var identifier: ToolIdentifier {
        Self.definition.identifier
    }

    var name: String {
        identifier.rawValue
    }

    var description: String {
        Self.definition.purpose
    }

    var risk: ActionRisk {
        Self.definition.risk
    }

    var semanticInputSchema: JSONSchema {
        Input.jsonschema
    }

    var inputSchema: JSONValue {
        semanticInputSchema.jsonvalue
    }

    var descriptor: ToolDescriptor {
        .init(
            identifier: Self.definition.identifier,
            description: Self.definition.purpose,
            input: inputSchema,
            risk: Self.definition.risk
        )
    }
}

