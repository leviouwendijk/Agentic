import Agentic

/// Finding and reaching what an agent may use: `capabilities_tool_search`
/// lists or searches, `capabilities_tool_inspect` returns one contract,
/// `capabilities_tool_call` calls one outside the tool definitions. The
/// runtime installs this domain in every application and grants its tools
/// as discovery.
@Domain("capabilities", aliases: ["capability"])
public enum Capabilities {}

public extension Capabilities.Tools {
    /// The discovery set: searching says what exists, inspecting returns one
    /// contract; inspection alone needs a name the model already has. A
    /// capability outside the tool definitions is called as inspection says:
    /// by name, or through `Call`.
    static let discovery: [ToolIdentifier] = [
        Search.identifier,
        Inspect.identifier,
        Call.identifier,
    ]
}

extension CapabilityFilter {
    /// This filter with domain names and aliases (`swift`, `sbm`) turned into
    /// the namespaces entries carry; a namespace given as is still matches.
    func resolvingDomains(_ definitions: [DomainDefinition]) -> CapabilityFilter {
        guard !domains.isEmpty else { return self }
        let namespaces = domains.map { name in
            definitions.first { definition in
                definition.names.contains { $0.raw == name }
            }?.namespace.rawValue ?? name
        }
        return .init(kinds: kinds, domains: namespaces, visibility: visibility, risks: risks)
    }
}

extension [DomainDefinition] {
    /// Namespace → primary name, for showing entries under the name the
    /// model calls them by.
    var primaryNames: [String: String] {
        var names: [String: String] = [:]
        for definition in self {
            if let name = definition.name {
                names[definition.namespace.rawValue] = name.raw
            }
        }
        return names
    }
}
