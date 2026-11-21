import Agentic
import Foundation
import Macros
import Schema

public extension Standard.Tools {
    @Tool
    struct ListCapabilities: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            /// Any of these kinds; all when omitted.
            public let kinds: [CapabilityKind]?
            /// Any of these domains (namespaces).
            public let domains: [String]?
            /// Only those among your tools (`visible`) or only the others.
            public let visibility: CapabilityVisibility?
            /// Any of these effect levels; capabilities without one do not match.
            public let risks: [ActionRisk]?
            public let offset: Int?
            public let maximumResults: Int?

            public init(
                kinds: [CapabilityKind]? = nil,
                domains: [String]? = nil,
                visibility: CapabilityVisibility? = nil,
                risks: [ActionRisk]? = nil,
                offset: Int? = nil,
                maximumResults: Int? = nil
            ) {
                self.kinds = kinds
                self.domains = domains
                self.visibility = visibility
                self.risks = risks
                self.offset = offset
                self.maximumResults = maximumResults
            }

            var filter: CapabilityFilter {
                .init(kinds: kinds, domains: domains, visibility: visibility, risks: risks)
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
            "Enumerate available capabilities, paginated, narrowed by kinds, domains, visibility or effect levels, without changing visibility or authority."
        public static let risk: ActionRisk = .observe
        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            let (snapshot, available) = try await CapabilityDiscovery.available(in: context)
            let filter = input.filter
            let selected = available.filter { entry in
                CapabilityKind(rawValue: entry.kind) != nil
                    && filter.matches(entry, visible: snapshot.visible)
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
                let arguments = input.filter.arguments + ["\"offset\": \(end)"]
                text += "\n\(Self.identifier.rawValue) {\(arguments.joined(separator: ", "))} continues."
            }
            return text
        }
    }
}
