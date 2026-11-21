@attached(
    member,
    names:
        named(definition),
        named(Agents),
        named(Instructions),
        named(Adapters),
        named(Inferences),
        named(Programs),
        named(Tools),
        named(Realizations),
        named(Optimizations)
)
@attached(
    extension,
    conformances: Domain
)
/// Declares a domain. `@Domain("swift", aliases: ["sbm", "swiftlang"])` gives
/// it a primary name, the `<domain>` in its capabilities' computed names
/// (`swift_tool_build`), and aliases. Aliases are accepted only by
/// `CapabilityResolver` when people or the model write a capability; they are
/// never shown to the model or stored. Without arguments the domain keeps its
/// capabilities' authored identifiers (the transition to computed names).
public macro Domain(
    _ name: String? = nil,
    aliases: [String] = []
) = #externalMacro(
    module: "AgenticMacrosPlugin",
    type: "DomainMacro"
)
