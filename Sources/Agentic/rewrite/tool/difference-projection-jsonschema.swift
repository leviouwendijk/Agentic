import Difference
import Schema

/// Schema adaptation for the Codable semantic projection transport.
/// The Kind union and coordinate range retain their native Codable shape.
/// Their nested representations are intentionally permitted rather than
/// independently redefined here.
public extension DifferenceLayout.Projection {
    static var jsonschema: JSONSchema {
        let openObject = JSONSchema.object(
            properties: [],
            additionalProperties: .allowed
        )
        let span = JSONSchema.object(
            properties: [
                .init(name: "range", schema: openObject, required: true)
            ],
            additionalProperties: .disallowed
        )
        let cell = JSONSchema.object(
            properties: [
                .init(name: "line", schema: Int.jsonschema, required: true),
                .init(name: "text", schema: String.jsonschema, required: true),
                .init(name: "role", schema: String.jsonschema, required: true),
                .init(name: "spans", schema: .array(items: span), required: true)
            ],
            additionalProperties: .disallowed
        )
        let row = JSONSchema.object(
            properties: [
                .init(name: "kind", schema: openObject, required: true),
                .init(name: "old", schema: cell, required: false),
                .init(name: "new", schema: cell, required: false),
                .init(name: "text", schema: String.jsonschema, required: true)
            ],
            additionalProperties: .disallowed
        )
        return .object(
            properties: [
                .init(name: "mode", schema: String.jsonschema, required: true),
                .init(name: "rows", schema: .array(items: row), required: true)
            ],
            additionalProperties: .disallowed
        )
    }
}
