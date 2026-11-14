import Primitives

public extension ToolDescriptor {
    /// The schema a call needs: required properties in full (with their
    /// calling guidance), optional properties without their prose; every
    /// field stays named and typed.
    /// `inspect_capability` returns the full schema. Unchanged when nothing
    /// is optional.
    var core: ToolDescriptor {
        guard let input else { return self }
        let (projected, abbreviated) = SchemaCore.project(input, required: true)
        guard abbreviated else { return self }
        return .init(
            identifier: identifier,
            description: description + " " + SchemaCore.notice,
            input: projected,
            risk: risk
        )
    }
}

enum SchemaCore {
    static let notice = "(Optional fields abbreviated; inspect_capability returns full details.)"
    /// Explanatory keys dropped from optional subtrees. Everything else
    /// (types, enums, properties, items, required) is kept, so every field
    /// stays named and typed at any depth.
    static let prose: Set<String> = ["description", "examples", "title", "$comment"]

    /// Projects a JSON schema node; reports whether anything was dropped.
    static func project(
        _ schema: JSONValue,
        required: Bool
    ) -> (JSONValue, abbreviated: Bool) {
        switch schema {
        case .array(let values):
            var abbreviated = false
            let projected = values.map { value -> JSONValue in
                let (result, dropped) = project(value, required: required)
                abbreviated = abbreviated || dropped
                return result
            }
            return (.array(projected), abbreviated)
        case .object(let node):
            let requiredNames: Set<String>
            if case .array(let names)? = node["required"] {
                requiredNames = Set(names.compactMap {
                    if case .string(let name) = $0 { return name }
                    return nil
                })
            } else {
                requiredNames = []
            }
            var abbreviated = false
            var kept: [String: JSONValue] = [:]
            for (key, value) in node {
                if !required, prose.contains(key) {
                    abbreviated = true
                    continue
                }
                switch key {
                case "properties":
                    guard case .object(let properties) = value else {
                        kept[key] = value
                        continue
                    }
                    var projected: [String: JSONValue] = [:]
                    for (name, property) in properties {
                        let (result, dropped) = project(
                            property,
                            required: required && requiredNames.contains(name)
                        )
                        projected[name] = result
                        abbreviated = abbreviated || dropped
                    }
                    kept[key] = .object(projected)
                case "items", "anyOf", "oneOf", "allOf":
                    let (result, dropped) = project(value, required: required)
                    kept[key] = result
                    abbreviated = abbreviated || dropped
                default:
                    kept[key] = value
                }
            }
            return (.object(kept), abbreviated)
        default:
            return (schema, false)
        }
    }
}
