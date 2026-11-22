import Foundation
import Agentic
import Macros
import Schema

public enum CapabilityDiscoveryError:
    Error,
    Sendable
{
    case agentCapabilityStateRequired
}

/// Whether a capability is among the tool definitions, and so called by its
/// own name, or callable without one.
public enum CapabilityVisibility:
    String,
    Sendable,
    Codable,
    Hashable,
    CaseIterable,
    JSONSchemaProviding
{
    case visible
    case hidden

    public static var jsonschema: JSONSchema {
        .string(
            cases: allCases.map(\.rawValue)
        )
    }
}

/// What `capabilities_tool_search` and `capabilities_tool_search` narrow to. Fields
/// combine with AND, the values within one with OR; an absent or empty
/// field narrows nothing. A risk filter matches only capabilities that
/// declare an effect level.
public struct CapabilityFilter: Sendable, Hashable {
    public let kinds: [CapabilityKind]
    public let domains: [String]
    public let visibility: CapabilityVisibility?
    public let risks: [ActionRisk]

    public init(
        kinds: [CapabilityKind]? = nil,
        domains: [String]? = nil,
        visibility: CapabilityVisibility? = nil,
        risks: [ActionRisk]? = nil
    ) {
        self.kinds = kinds ?? []
        self.domains = (domains ?? [])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        self.visibility = visibility
        self.risks = risks ?? []
    }

    func matches(
        _ inspection: CapabilityInspection,
        visible: AgentCapabilitySet
    ) -> Bool {
        if !kinds.isEmpty, !kinds.contains(where: { $0.rawValue == inspection.kind }) {
            return false
        }
        if !domains.isEmpty, !domains.contains(inspection.namespace?.lowercased() ?? "") {
            return false
        }
        if let visibility,
           CapabilityDiscovery.contains(inspection.reference, in: visible) != (visibility == .visible) {
            return false
        }
        if !risks.isEmpty {
            guard let risk = inspection.risk, risks.contains(risk) else { return false }
        }
        return true
    }

    /// The filter as arguments, for a call that continues a listing.
    var arguments: [String] {
        func list(_ values: [String]) -> String {
            "[" + values.map { "\"\($0)\"" }.joined(separator: ", ") + "]"
        }
        var arguments: [String] = []
        if !kinds.isEmpty { arguments.append("\"kinds\": " + list(kinds.map(\.rawValue))) }
        if !domains.isEmpty { arguments.append("\"domains\": " + list(domains)) }
        if let visibility { arguments.append("\"visibility\": \"\(visibility.rawValue)\"") }
        if !risks.isEmpty { arguments.append("\"risks\": " + list(risks.map(\.rawValue))) }
        return arguments
    }
}

/// One available capability as discovery reports it: enough to choose it
/// and to name it to `capabilities_tool_inspect`, nothing of its contract.
@JSONSchema
public struct CapabilityEntry: HashableProduct
{
    public let kind: CapabilityKind
    public let identifier: String
    public let namespace: String?
    public let purpose: String
    public let wasVisible: Bool

    public init(
        kind: CapabilityKind,
        identifier: String,
        namespace: String?,
        purpose: String,
        wasVisible: Bool
    ) {
        self.kind = kind
        self.identifier = identifier
        self.namespace = namespace
        self.purpose = purpose
        self.wasVisible = wasVisible
    }
}


extension CapabilityEntry {
    /// What the model reads: one line per entry under its namespace, in the
    /// given order. JSON would repeat every key per entry.
    static func rendered(_ entries: [CapabilityEntry]) -> String {
        var lines: [String] = []
        var namespace: String??
        for entry in entries {
            if namespace != .some(entry.namespace) {
                namespace = .some(entry.namespace)
                lines.append(entry.namespace ?? "(no namespace)")
            }
            var line = "  " + entry.identifier
            if entry.kind != .tool { line += " [\(entry.kind.rawValue)]" }
            if entry.wasVisible { line += " ·visible" }
            lines.append(line + " — " + entry.purpose)
        }
        return lines.joined(separator: "\n")
    }
}
