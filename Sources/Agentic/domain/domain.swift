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
    public let namespace: Namespace

    public init(
        namespace: Namespace
    ) {
        self.namespace = namespace
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
