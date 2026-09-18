@attached(
    member,
    names:
        named(definition),
        named(Agents),
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
public macro Domain() = #externalMacro(
    module: "AgenticMacrosPlugin",
    type: "DomainMacro"
)
