import Agentic
import Foundation
import Macros
import Schema

public extension Standard.Tools {
    @Tool
    struct ListCapabilities: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            public let kind: CapabilityKind?
            public let domain: String?
            public let offset: Int?
            public let maximumResults: Int?

            public init(
                kind: CapabilityKind? = nil,
                domain: String? = nil,
                offset: Int? = nil,
                maximumResults: Int? = nil
            ) {
                self.kind = kind
                self.domain = domain
                self.offset = offset
                self.maximumResults = maximumResults
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let total: Int
            public let offset: Int
            public let entries: [CapabilityEntry]

            public init(total: Int, offset: Int, entries: [CapabilityEntry]) {
                self.total = total
                self.offset = offset
                self.entries = entries
            }
        }

        public static let purpose =
            "Enumerate available executable capabilities by domain, paginated, without changing visibility or authority."
        public static let risk: ActionRisk = .observe
        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            let (snapshot, available) = try await CapabilityDiscovery.available(in: context)
            let domain = input.domain?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let selected = available.filter { entry in
                guard let kind = CapabilityKind(rawValue: entry.kind) else { return false }
                if let wanted = input.kind, wanted != .all && wanted != kind { return false }
                if let domain, !domain.isEmpty, entry.namespace?.lowercased() != domain {
                    return false
                }
                return true
            }.sorted { lhs, rhs in
                // Pages read as domains: grouped by namespace, then kind and name.
                if lhs.namespace != rhs.namespace { return (lhs.namespace ?? "") < (rhs.namespace ?? "") }
                if lhs.kind != rhs.kind { return lhs.kind < rhs.kind }
                return lhs.identifier < rhs.identifier
            }
            let offset = min(selected.count, max(0, input.offset ?? 0))
            let limit = min(50, max(1, input.maximumResults ?? 20))
            let page = selected.dropFirst(offset).prefix(limit)
            let entries = page.compactMap { entry -> CapabilityEntry? in
                guard let kind = CapabilityKind(rawValue: entry.kind) else { return nil }
                return .init(
                    kind: kind,
                    identifier: entry.identifier,
                    namespace: entry.namespace,
                    purpose: entry.purpose,
                    wasVisible: CapabilityDiscovery.contains(entry.reference, in: snapshot.visible)
                )
            }
            return .init(total: selected.count, offset: offset, entries: entries)
        }

        public func render(_ output: Output, input: Input) -> String? {
            guard !output.entries.isEmpty else {
                return output.total == 0
                    ? "No available capabilities match."
                    : "No entries from offset \(output.offset); \(output.total) in total."
            }
            let end = output.offset + output.entries.count
            var text = "\(output.offset + 1)–\(end) of \(output.total):\n"
                + CapabilityEntry.rendered(output.entries)
            if end < output.total {
                var arguments = ["\"offset\": \(end)"]
                if let kind = input.kind { arguments.insert("\"kind\": \"\(kind.rawValue)\"", at: 0) }
                if let domain = input.domain { arguments.insert("\"domain\": \"\(domain)\"", at: 0) }
                text += "\nlist_capabilities {\(arguments.joined(separator: ", "))} continues."
            }
            return text
        }
    }
}
