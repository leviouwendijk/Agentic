import Primitives

public struct Namespace:
    StringIdentifier
{
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }
}

public struct DomainDefinition:
    Definition,
    Codable,
    Hashable
{
    /// Groups the domain's catalog entries: snake_case of the domain's Swift name.
    public let namespace: Namespace
    /// The primary name, the `<domain>` of `<domain>_<kind>_<name>` and the
    /// one people are shown. Nil while the domain has not moved to computed
    /// names: its capabilities keep their authored identifiers unchanged.
    public let name: DomainName?
    /// Other names people may write for this domain (`sbm` for `swift`).
    /// Accepted only by `CapabilityResolver`, which maps them to `name`;
    /// never shown to the model, never stored, never looked up anywhere else.
    public let aliases: [DomainName]

    public init(
        namespace: Namespace,
        name: DomainName? = nil,
        aliases: [DomainName] = []
    ) {
        self.namespace = namespace
        self.name = name
        self.aliases = aliases
    }

    /// The primary name, then the aliases.
    public var names: [DomainName] {
        (name.map { [$0] } ?? []) + aliases
    }

    /// The identity of a capability this domain declares; nil while the
    /// domain has no primary name. `@Domain` validated both at compile time.
    public func identity(
        _ kind: CapabilityKind,
        _ name: String
    ) -> CapabilityIdentity? {
        guard let domain = self.name,
              let name = try? CapabilityName(name)
        else {
            return nil
        }
        return try? CapabilityIdentity(domain: domain, kind: kind, name: name)
    }

    /// A tool's identifier: `<domain>_tool_<name>` once the domain has a
    /// primary name, until then the authored `name` unchanged.
    public func toolIdentifier(
        _ name: String
    ) -> ToolIdentifier {
        ToolIdentifier(rawValue: identity(.tool, name)?.string ?? name)
    }
}

public protocol Domain:
    Sendable,
    CatalogProviding
{
    static var definition: DomainDefinition { get }
}

public extension Domain {
    static var namespace: Namespace {
        definition.namespace
    }

    static var installation: DomainInstallation {
        _agentic_domain_installation(
            namespace: definition.namespace.rawValue
        )
    }

    static var catalog: Catalog {
        Catalog(
            domains: [
                definition,
            ],
            entries: _agentic_catalog_entries(
                namespace: definition.namespace.rawValue
            )
        )
    }
}
