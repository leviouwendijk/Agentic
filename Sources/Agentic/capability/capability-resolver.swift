import Errors
import Foundation

/// Turns what people or the model write for a capability into one of the
/// capabilities on offer.
///
/// **This is the only place that accepts domain aliases, `domain.name` and
/// bare names.** Everything past it (registry, projection, runtime, logs,
/// permissions) takes the full `<domain>_<kind>_<name>` string, which is the
/// identifier itself, and never looks up an alias. Do not add a second
/// lookup path; route new input through here.
///
/// Accepted, for `kind` (tool unless the caller says otherwise):
/// - an identifier on offer, exactly (`swift_tool_build`, or an authored
///   identifier of a domain without a primary name yet);
/// - the full form with an alias for the domain (`sbm_tool_build`);
/// - `domain.name`, with the primary name or an alias (`swift.build`, `sbm.build`);
/// - a bare name (`build`), narrowed by `domain` when given.
///
/// A bare name two domains share is `ambiguous`, with every candidate listed.
public struct CapabilityResolver: Sendable {
    public let domains: [DomainDefinition]

    public init(
        domains: [DomainDefinition]
    ) {
        self.domains = domains
    }

    /// The identifier among `candidates` that `text` (and `domain`, when
    /// given) means.
    public func resolve(
        _ text: String,
        domain: String? = nil,
        kind: CapabilityKind = .tool,
        among candidates: [String]
    ) throws(CapabilityReferenceError) -> String {
        let text = text.trimmingCharacters(in: .whitespaces)
        var given: DomainName?
        if let domain {
            given = try primary(for: domain)
        }

        if given == nil, candidates.contains(text) {
            return text
        }

        let identities: [(identifier: String, identity: CapabilityIdentity)] = candidates.compactMap { candidate in
            guard let identity = try? CapabilityIdentity(parsing: candidate),
                  identity.kind == kind,
                  namedDomains.contains(identity.domain)
            else {
                return nil
            }
            return (candidate, identity)
        }

        let wantedDomain: DomainName?
        let wantedName: String
        if let dot = text.firstIndex(of: ".") {
            let written = try primary(for: String(text[..<dot]))
            if let given, given != written {
                throw .conflictingDomain(given: given.raw, written: written.raw)
            }
            wantedDomain = written
            wantedName = String(text[text.index(after: dot)...])
        } else if let full = try? CapabilityIdentity(parsing: text),
                  full.kind == kind,
                  let written = try? primary(for: full.domain.raw) {
            if let given, given != written {
                throw .conflictingDomain(given: given.raw, written: written.raw)
            }
            wantedDomain = written
            wantedName = full.name.raw
        } else {
            wantedDomain = given
            wantedName = text
        }

        let matches = identities.filter { entry in
            entry.identity.name.raw == wantedName
                && (wantedDomain == nil || entry.identity.domain == wantedDomain)
        }
        switch matches.count {
        case 1:
            return matches[0].identifier
        case 0:
            throw .notFound(text)
        default:
            throw .ambiguous(
                text,
                candidates: matches.map(\.identifier).sorted(),
                domains: matches.map(\.identity.domain.raw).sorted()
            )
        }
    }

    /// The primary name `name` stands for: a primary name or an alias.
    public func primary(
        for name: String
    ) throws(CapabilityReferenceError) -> DomainName {
        for definition in domains {
            guard let primary = definition.name else { continue }
            if definition.names.contains(where: { $0.raw == name }) {
                return primary
            }
        }
        throw .unknownDomain(name, known: domains.compactMap(\.name?.raw).sorted())
    }

    private var namedDomains: Set<DomainName> {
        Set(domains.compactMap(\.name))
    }
}

public enum CapabilityReferenceError:
    Error,
    Sendable,
    Equatable,
    LocalizedError,
    ErrorDispositionProviding
{
    case unknownDomain(String, known: [String])
    case notFound(String)
    case ambiguous(String, candidates: [String], domains: [String])
    case conflictingDomain(given: String, written: String)

    public var errorDescription: String? {
        switch self {
        case .unknownDomain(let name, let known):
            "'\(name)' is not a domain. Domains: \(known.joined(separator: ", "))."
        case .notFound(let text):
            "No capability on offer is called '\(text)'. Find it with list_capabilities or search_capabilities."
        case .ambiguous(let text, let candidates, let domains):
            "'\(text)' is ambiguous: \(candidates.map { "`\($0)`" }.joined(separator: ", ")). "
                + "Pass domain (\(domains.map { "\"\($0)\"" }.joined(separator: " or "))), or use the full name."
        case .conflictingDomain(let given, let written):
            "domain is '\(given)' but the name says '\(written)'; give one."
        }
    }

    public var errorDisposition: ErrorDisposition? { .invalid_input }
}
