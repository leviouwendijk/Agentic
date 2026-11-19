import Agentic
import Macros
import Schema

public enum CapabilityDiscoveryError:
    Error,
    Sendable
{
    case agentCapabilityStateRequired
}

public enum CapabilityKind:
    String,
    Sendable,
    Codable,
    Hashable,
    CaseIterable,
    JSONSchemaProviding
{
    case all
    case tool
    case program
    case inference
    case agent

    public static var jsonschema: JSONSchema {
        .string(
            cases: allCases.map(\.rawValue)
        )
    }
}

/// One available capability as discovery reports it: enough to choose it
/// and to name it to `inspect_capability`, nothing of its contract.
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

public extension Standard.Tools {
    /// The discovery set. Listing says what exists, searching narrows it,
    /// inspecting returns one contract; inspection alone needs an identifier
    /// the model already has. The runtime exposes every installed one.
    static let discovery: [ToolIdentifier] = [
        ListCapabilities.identifier,
        SearchCapabilities.identifier,
        InspectCapability.identifier,
    ]
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
