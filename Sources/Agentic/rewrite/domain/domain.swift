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

    static var catalog: Catalog {
        Catalog(
            domains: [
                definition,
            ],
            declarations: _agentic_catalog_declarations(
                namespace: definition.namespace.rawValue
            )
        )
    }
}
