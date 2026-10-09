public protocol CatalogProviding: Sendable {
    static var catalog: Catalog { get }
}

public struct Catalog:
    Sendable,
    Hashable
{
    public let domains: [DomainDefinition]
    public let entries: [Entry]

    public var declarations: [Declaration] {
        entries.map(\.declaration)
    }

    public init(
        domains: [DomainDefinition] = [],
        entries: [Entry]
    ) {
        self.domains = domains
        self.entries = entries
    }

    public init(
        domains: [DomainDefinition] = [],
        declarations: [Declaration] = []
    ) {
        self.init(
            domains: domains,
            entries: declarations.map { declaration in
                Entry(
                    declaration: declaration
                )
            }
        )
    }

    public static let none = Self()

    public static var unscoped: Self {
        .init(
            entries: _agentic_catalog_entries(
                namespace: nil
            )
        )
    }

    public static func + (
        lhs: Self,
        rhs: Self
    ) -> Self {
        .init(
            domains:
                lhs.domains
                + rhs.domains,
            entries:
                lhs.entries
                + rhs.entries
        )
    }
}

public extension Catalog {
    struct Entry:
        Sendable,
        Hashable
    {
        public let namespace: Namespace?
        public let declaration: Declaration

        public init(
            namespace: Namespace? = nil,
            declaration: Declaration
        ) {
            self.namespace = namespace
            self.declaration = declaration
        }
    }

    enum Declaration:
        Sendable,
        Hashable
    {
        case tool(ToolDefinition)
        case program(ProgramDefinition)
        case inference(InferenceDefinition)
        case agent(AgentDefinition)
        case adapter(InferenceAdapterDefinition)
    }

    var tools: [ToolDefinition] {
        declarations.compactMap { declaration in
            guard case .tool(let definition) = declaration else {
                return nil
            }

            return definition
        }
    }

    var programs: [ProgramDefinition] {
        declarations.compactMap { declaration in
            guard case .program(let definition) = declaration else {
                return nil
            }

            return definition
        }
    }

    var inferences: [InferenceDefinition] {
        declarations.compactMap { declaration in
            guard case .inference(let definition) = declaration else {
                return nil
            }

            return definition
        }
    }

    var adapters: [InferenceAdapterDefinition] {
        declarations.compactMap { declaration in
            guard case .adapter(let definition) = declaration else { return nil }
            return definition
        }
    }

    var agents: [AgentDefinition] {
        declarations.compactMap { declaration in
            guard case .agent(let definition) = declaration else {
                return nil
            }

            return definition
        }
    }
}
