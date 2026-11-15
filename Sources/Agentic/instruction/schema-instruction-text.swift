import Schema

/// Instruction text rendered from a type's schema. Field names and value
/// meanings come from the declarations and their doc comments, so prompt
/// vocabulary cannot drift from the types it describes.
public enum SchemaInstructionText {
    /// One `- name: description` line per property, in declared order.
    public static func fields<Value: JSONSchemaProviding>(
        of type: Value.Type
    ) -> String {
        properties(of: type).map { property in
            line(
                property.name,
                property.description ?? property.schema.description
            )
        }
        .joined(separator: "\n")
    }

    /// One `- value: description` line per enumerated value, in declared order.
    public static func values<Value: JSONSchemaProviding>(
        of type: Value.Type
    ) -> String {
        let schema = type.jsonschema
        return cases(of: type).map { value in
            line(value, schema.caseDescriptions[value])
        }
        .joined(separator: "\n")
    }

    /// Properties without a description; empty when the type is fully documented.
    public static func undocumentedFields<Value: JSONSchemaProviding>(
        of type: Value.Type
    ) -> [String] {
        properties(of: type).filter { property in
            (property.description ?? property.schema.description)?.isEmpty ?? true
        }
        .map(\.name)
    }

    /// Enumerated values without a description; empty when fully documented.
    public static func undocumentedValues<Value: JSONSchemaProviding>(
        of type: Value.Type
    ) -> [String] {
        let schema = type.jsonschema
        return cases(of: type).filter { value in
            schema.caseDescriptions[value]?.isEmpty ?? true
        }
    }

    private static func properties<Value: JSONSchemaProviding>(
        of type: Value.Type
    ) -> [JSONSchema.Property] {
        guard case .object(let properties, _) = type.jsonschema.form else {
            return []
        }
        return properties
    }

    private static func cases<Value: JSONSchemaProviding>(
        of type: Value.Type
    ) -> [String] {
        guard case .string(let cases) = type.jsonschema.form else {
            return []
        }
        return cases
    }

    private static func line(
        _ name: String,
        _ description: String?
    ) -> String {
        guard let description, !description.isEmpty else {
            return "- \(name)"
        }
        // Doc comments wrap at source width; one entry reads as one line.
        let flowed = description
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: " ")
        return "- \(name): \(flowed)"
    }
}
