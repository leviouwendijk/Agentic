import Difference
import Schema

/// Schema for source-backed preflight transport.
/// Keep this adaptation in Agentic; Difference remains presentation independent.
public extension TextDifference {
    static var jsonschema: JSONSchema {
        let lineSchema = JSONSchema.object(
            properties: [
                .init(name: "operation", schema: String.jsonschema, required: true),
                .init(name: "text", schema: String.jsonschema, required: true),
                .init(name: "oldLine", schema: Int.jsonschema, required: false),
                .init(name: "newLine", schema: Int.jsonschema, required: false),
                .init(name: "ending", schema: String.jsonschema, required: false)
            ],
            additionalProperties: .disallowed
        )

        return .object(
            properties: [
                .init(name: "oldName", schema: String.jsonschema, required: true),
                .init(name: "newName", schema: String.jsonschema, required: true),
                .init(name: "lines", schema: .array(items: lineSchema), required: true),
                .init(name: "quality", schema: String.jsonschema, required: false)
            ],
            additionalProperties: .disallowed
        )
    }
}
