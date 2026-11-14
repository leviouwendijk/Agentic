import Primitives

public extension ToolDescriptor {
    /// The schema a call needs: required properties in full (with their
    /// calling guidance), optional properties as name, type and enum only.
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

    /// Projects a JSON schema node; reports whether anything was dropped.
    static func project(
        _ schema: JSONValue,
        required: Bool
    ) -> (JSONValue, abbreviated: Bool) {
        guard case .object(let node) = schema else {
            return (schema, false)
        }
        guard required else {
            var kept = node.filter { $0.key == "type" || $0.key == "enum" }
            if case .object(let items)? = node["items"], items["enum"] != nil {
                kept["items"] = .object(items.filter { $0.key == "type" || $0.key == "enum" })
            }
            return (.object(kept), kept.count < node.count || kept["items"] != node["items"])
        }

        var abbreviated = false
        var kept = node
        if case .object(let properties)? = node["properties"] {
            let requiredNames: Set<String>
            if case .array(let names)? = node["required"] {
                requiredNames = Set(names.compactMap {
                    if case .string(let name) = $0 { return name }
                    return nil
                })
            } else {
                requiredNames = []
            }
            var projected: [String: JSONValue] = [:]
            for (name, property) in properties {
                let (value, dropped) = project(property, required: requiredNames.contains(name))
                projected[name] = value
                abbreviated = abbreviated || dropped
            }
            kept["properties"] = .object(projected)
        }
        if let items = node["items"] {
            let (value, dropped) = project(items, required: true)
            kept["items"] = value
            abbreviated = abbreviated || dropped
        }
        return (.object(kept), abbreviated)
    }
}
