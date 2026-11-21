import Errors
import Foundation

/// What can be wrong with the names in a catalog. A macro sees one
/// declaration at a time, so these are checked when catalogs are combined:
/// by the runtime when it installs domains, and by the tests that load every
/// domain package.
public enum CatalogNamingProblem:
    Sendable,
    Hashable,
    CustomStringConvertible
{
    /// Two domains claim the same primary name or alias.
    case duplicateDomainName(String, namespaces: [String])
    /// Two different capabilities share an identifier.
    case duplicateIdentifier(String, kind: CapabilityKind)
    /// A tool of a named domain whose identifier is not
    /// `<domain>_tool_<name>`: its name is invalid or the string is too long.
    case uncomputedIdentifier(String, domain: String)

    public var description: String {
        switch self {
        case .duplicateDomainName(let name, let namespaces):
            "Domain name '\(name)' is claimed by \(namespaces.joined(separator: " and "))."
        case .duplicateIdentifier(let identifier, let kind):
            "Two \(kind.rawValue)s are called '\(identifier)'."
        case .uncomputedIdentifier(let identifier, let domain):
            "Tool '\(identifier)' of domain '\(domain)' is not \(domain)_tool_<name>: its name is invalid or longer than \(CapabilityIdentity.limit) characters in full."
        }
    }
}

public struct CatalogNamingError:
    Error,
    Sendable,
    LocalizedError,
    ErrorDispositionProviding
{
    public let problems: [CatalogNamingProblem]

    public var errorDescription: String? {
        "Capability names clash: " + problems.map(\.description).joined(separator: " ")
    }

    public var errorDisposition: ErrorDisposition? { .permanent }
}

public extension Catalog {
    /// Every naming problem among these domains and their capabilities.
    var namingProblems: [CatalogNamingProblem] {
        var problems: [CatalogNamingProblem] = []

        var claims: [String: Set<String>] = [:]
        for domain in Set(domains) {
            for name in domain.names {
                claims[name.raw, default: []].insert(domain.namespace.rawValue)
            }
        }
        for (name, namespaces) in claims.sorted(by: { $0.key < $1.key }) where namespaces.count > 1 {
            problems.append(.duplicateDomainName(name, namespaces: namespaces.sorted()))
        }

        let named = Dictionary(
            Set(domains).compactMap { domain in domain.name.map { (domain.namespace, $0) } },
            uniquingKeysWith: { first, _ in first }
        )
        var tools: [String: Set<ToolDefinition>] = [:]
        for entry in Set(entries) {
            guard case .tool(let definition) = entry.declaration else { continue }
            tools[definition.identifier.rawValue, default: []].insert(definition)
            guard let namespace = entry.namespace, let domain = named[namespace] else { continue }
            let identity = try? CapabilityIdentity(parsing: definition.identifier.rawValue)
            if identity?.domain != domain || identity?.kind != .tool {
                problems.append(.uncomputedIdentifier(definition.identifier.rawValue, domain: domain.raw))
            }
        }
        for (identifier, definitions) in tools.sorted(by: { $0.key < $1.key }) where definitions.count > 1 {
            problems.append(.duplicateIdentifier(identifier, kind: .tool))
        }

        return problems
    }

    /// Throws when `namingProblems` is not empty.
    func validateNames() throws(CatalogNamingError) {
        let problems = namingProblems
        guard problems.isEmpty else {
            throw CatalogNamingError(problems: problems)
        }
    }
}
