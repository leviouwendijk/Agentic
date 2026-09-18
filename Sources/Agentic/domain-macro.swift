@attached(
    member,
    names:
        named(definition),
        named(Agents),
        named(Inferences),
        named(Programs),
        named(Tools),
        named(Realizations)
)
@attached(
    extension,
    conformances: Domain
)
public macro Domain() = #externalMacro(
    module: "AgenticMacrosPlugin",
    type: "DomainMacro"
)
