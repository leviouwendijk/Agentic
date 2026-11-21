import Errors
import Foundation
import Primitives

/// The middle part of `<domain>_<kind>_<name>`: what a capability is.
public enum CapabilityKind:
    String,
    Sendable,
    Codable,
    Hashable,
    CaseIterable
{
    case tool
    case program
    case agent
    case inference
}

/// A domain's primary name or one of its aliases: `[a-z][a-z0-9]*`, with no
/// underscore, so `<domain>_<kind>_<name>` splits back at its first two
/// underscores.
public struct DomainName:
    CodableInvariant,
    Sendable,
    Hashable,
    Comparable,
    CustomStringConvertible
{
    public let raw: String

    public init(_ raw: String) throws(CapabilityNameError) {
        guard let first = raw.unicodeScalars.first,
              ("a"..."z").contains(first),
              raw.unicodeScalars.allSatisfy({ ("a"..."z").contains($0) || ("0"..."9").contains($0) })
        else {
            throw .invalidDomainName(raw)
        }
        self.raw = raw
    }

    public var description: String { raw }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.raw < rhs.raw }
}

/// A capability's name within its domain and kind: `[a-z][a-z0-9_]*`.
public struct CapabilityName:
    CodableInvariant,
    Sendable,
    Hashable,
    Comparable,
    CustomStringConvertible
{
    public let raw: String

    public init(_ raw: String) throws(CapabilityNameError) {
        guard let first = raw.unicodeScalars.first,
              ("a"..."z").contains(first),
              raw.unicodeScalars.allSatisfy({
                  ("a"..."z").contains($0) || ("0"..."9").contains($0) || $0 == "_"
              })
        else {
            throw .invalidName(raw)
        }
        self.raw = raw
    }

    public var description: String { raw }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.raw < rhs.raw }
}

/// A capability as three values. Its `raw` string, `<domain>_<kind>_<name>`
/// (`swift_tool_build`), is the name the model sees and calls, and the
/// identifier everything stores (logs, permissions, profiles). People see
/// it rendered from the parts instead.
public struct CapabilityIdentity:
    CodableInvariant,
    Sendable,
    Hashable,
    CustomStringConvertible
{
    /// The strictest provider's limit on a function name. A longer string is
    /// a catalog error, never a shortened or hashed name.
    public static let limit = 64

    public let domain: DomainName
    public let kind: CapabilityKind
    public let name: CapabilityName

    public init(
        domain: DomainName,
        kind: CapabilityKind,
        name: CapabilityName
    ) throws(CapabilityNameError) {
        let raw = Self.raw(domain: domain, kind: kind, name: name)
        guard raw.count <= Self.limit else {
            throw .tooLong(raw)
        }
        self.domain = domain
        self.kind = kind
        self.name = name
    }

    /// Parses the full form `<domain>_<kind>_<name>` and nothing else. It
    /// never accepts an alias, `domain.name` or a bare name: those are
    /// accepted only by `CapabilityReference.init(_: CapabilityReference.Raw)`,
    /// the one place that turns human or model input into a capability. A
    /// string that parses is not necessarily a capability; check its domain
    /// against the installed ones.
    public init(_ raw: String) throws(CapabilityNameError) {
        let parts = raw.split(separator: "_", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count == 3,
              let kind = CapabilityKind(rawValue: String(parts[1]))
        else {
            throw .notQualified(raw)
        }
        try self.init(
            domain: DomainName(String(parts[0])),
            kind: kind,
            name: CapabilityName(String(parts[2]))
        )
    }

    /// `<domain>_<kind>_<name>`.
    public var raw: String {
        Self.raw(domain: domain, kind: kind, name: name)
    }

    public var description: String { raw }

    private static func raw(
        domain: DomainName,
        kind: CapabilityKind,
        name: CapabilityName
    ) -> String {
        "\(domain.raw)_\(kind.rawValue)_\(name.raw)"
    }
}

public enum CapabilityNameError:
    Error,
    Sendable,
    Equatable,
    LocalizedError,
    ErrorDispositionProviding
{
    case invalidDomainName(String)
    case invalidName(String)
    case notQualified(String)
    case tooLong(String)

    public var errorDescription: String? {
        switch self {
        case .invalidDomainName(let name):
            "'\(name)' is not a domain name: lowercase letters and digits, starting with a letter, no underscore."
        case .invalidName(let name):
            "'\(name)' is not a capability name: lowercase letters, digits and underscores, starting with a letter."
        case .notQualified(let text):
            "'\(text)' is not <domain>_<kind>_<name> with kind tool, program, agent or inference."
        case .tooLong(let string):
            "'\(string)' is longer than \(CapabilityIdentity.limit) characters, the provider limit on a function name."
        }
    }

    public var errorDisposition: ErrorDisposition? { .invalid_input }
}
