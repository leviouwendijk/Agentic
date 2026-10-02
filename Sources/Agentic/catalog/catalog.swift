public protocol CatalogProviding: Sendable {
    static var catalog: Catalog { get }
}

public struct Catalog:
    Sendable,
    Hashable
{
    public let domains: [DomainDefinition]
    public let declarations: [Declaration]

    public init(
        domains: [DomainDefinition] = [],
        declarations: [Declaration] = []
    ) {
        self.domains = domains
        self.declarations = declarations
    }

    public static let none = Self()

    public static func + (
        lhs: Self,
        rhs: Self
    ) -> Self {
        .init(
            domains:
                lhs.domains
                + rhs.domains,
            declarations:
                lhs.declarations
                + rhs.declarations
        )
    }
}

public extension Catalog {
    enum Declaration:
        Sendable,
        Hashable
    {
        case tool(ToolDefinition)
        case program(ProgramDefinition)
        case inference(InferenceDefinition)
        case agent(AgentDefinition)
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

    var agents: [AgentDefinition] {
        declarations.compactMap { declaration in
            guard case .agent(let definition) = declaration else {
                return nil
            }

            return definition
        }
    }
}
