import Errors
import Foundation
import Primitives

public extension CapabilityReference {
    /// What people or the model wrote for a capability, with what it is
    /// resolved against: the installed domains and the capabilities on offer.
    ///
    /// **`CapabilityReference.init(_: Raw)` is the only place that accepts
    /// domain aliases, `domain.name` and bare names.** Everything past it
    /// (registry, projection, runtime, logs, permissions) takes the full
    /// `<domain>_<kind>_<name>` string, which is the identifier itself, and
    /// never looks up an alias. Do not add a second lookup path; route new
    /// input through here.
    ///
    /// Accepted for `kind`:
    /// - an identifier on offer, exactly (`swift_tool_build`, or an authored
    ///   identifier of a domain without a primary name yet);
    /// - the full form with an alias for the domain (`sbm_tool_build`);
    /// - `domain.name`, with the primary name or an alias (`swift.build`,
    ///   `sbm.build`); a prefix that is not a domain leaves the text a name;
    /// - a bare name (`build`), narrowed by `domain` when given.
    struct Raw: Sendable, Hashable {
        public var text: String
        public var domain: String?
        public var kind: CapabilityKind
        public var domains: [DomainDefinition]
        public var offered: [CapabilityReference]

        public init(
            _ text: String,
            domain: String? = nil,
            kind: CapabilityKind = .tool,
            domains: [DomainDefinition],
            offered: [CapabilityReference]
        ) {
            self.text = text
            self.domain = domain
            self.kind = kind
            self.domains = domains
            self.offered = offered
        }
    }
}

extension CapabilityReference: Invariant {
    /// The capability on offer that `raw` means. A bare name two domains
    /// share is `ambiguous`, with every candidate listed.
    public init(_ raw: Raw) throws(CapabilityReferenceError) {
        let text = raw.text.trimmingCharacters(in: .whitespaces)
        let offered = raw.offered.filter { $0.capabilityKind == raw.kind }
        var given: DomainName?
        if let domain = raw.domain {
            given = try raw.primary(for: domain)
        }

        if given == nil, let exact = offered.first(where: { $0.identifierText == text }) {
            self = exact
            return
        }

        let named = Set(raw.domains.compactMap(\.name))
        let identities: [(reference: CapabilityReference, identity: CapabilityIdentity)] = offered.compactMap { reference in
            guard let identity = try? CapabilityIdentity(reference.identifierText),
                  named.contains(identity.domain)
            else {
                return nil
            }
            return (reference, identity)
        }

        let wantedDomain: DomainName?
        let wantedName: String
        if let dot = text.firstIndex(of: "."),
           let written = try? raw.primary(for: String(text[..<dot])) {
            // A prefix that is no domain leaves the whole text a name: agent
            // and program identifiers have dots of their own.
            if let given, given != written {
                throw .conflictingDomain(given: given.raw, written: written.raw)
            }
            wantedDomain = written
            wantedName = String(text[text.index(after: dot)...])
        } else if let full = try? CapabilityIdentity(text),
                  full.kind == raw.kind,
                  let written = try? raw.primary(for: full.domain.raw) {
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
            self = matches[0].reference
        case 0:
            throw .notFound(text)
        default:
            throw .ambiguous(
                text,
                candidates: matches.map(\.identity.raw).sorted(),
                domains: matches.map(\.identity.domain.raw).sorted()
            )
        }
    }
}

extension CapabilityReference.Raw {
    /// The primary name `name` stands for: a primary name or an alias.
    func primary(
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
}

public extension CapabilityReference {
    var capabilityKind: CapabilityKind {
        switch self {
        case .tool: .tool
        case .program: .program
        case .inference: .inference
        case .agent: .agent
        }
    }
}

private extension CapabilityReference {
    var identifierText: String {
        switch self {
        case .tool(let identifier): identifier.rawValue
        case .program(let identifier): identifier.rawValue
        case .inference(let identifier): identifier.rawValue
        case .agent(let identifier): identifier.rawValue
        }
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
            known.isEmpty
                ? "'\(name)' is not a domain; no domain has a name yet."
                : "'\(name)' is not a domain. Domains: \(known.joined(separator: ", "))."
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
