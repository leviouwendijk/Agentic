import Agentic
import Foundation
import Macros
import Primitives
import Schema

public extension Capabilities.Tools {
    /// One tool for what used to be listing and searching. Without a query it
    /// lists, grouped by domain; with one it ranks the matches. Both page with
    /// `offset`, and both narrow by kinds, domains, visibility and effect.
    @Tool("search")
    struct Search: Tool {
        public struct Input: HashableSource, CodableInvariant {
            @JSONSchema
            public struct Raw: HashableSource {
                /// Words to match against names, domains and purposes; omit to list.
                public var query: String?
                /// Any of these kinds; all when omitted.
                public var kinds: [CapabilityKind]?
                /// Any of these domains, by name or alias (`swift`, `sbm`).
                public var domains: [String]?
                /// Only those among your tools (`visible`) or only the others.
                public var visibility: CapabilityVisibility?
                /// Any of these effect levels; capabilities without one do not match.
                public var risks: [ActionRisk]?
                /// Where to continue a listing or a ranking.
                public var offset: Int?
                /// Defaults to 20 when listing and 8 when searching; at most 50.
                public var maximumResults: Int?

                public init(
                    query: String? = nil,
                    kinds: [CapabilityKind]? = nil,
                    domains: [String]? = nil,
                    visibility: CapabilityVisibility? = nil,
                    risks: [ActionRisk]? = nil,
                    offset: Int? = nil,
                    maximumResults: Int? = nil
                ) {
                    self.query = query
                    self.kinds = kinds
                    self.domains = domains
                    self.visibility = visibility
                    self.risks = risks
                    self.offset = offset
                    self.maximumResults = maximumResults
                }
            }

            /// Lowercased and trimmed; nil lists.
            public let query: String?
            public let filter: CapabilityFilter
            public let offset: Int
            public let maximumResults: Int

            public init(_ raw: Raw) {
                let query = raw.query?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                self.query = query?.isEmpty == false ? query : nil
                self.filter = .init(
                    kinds: raw.kinds,
                    domains: raw.domains,
                    visibility: raw.visibility,
                    risks: raw.risks
                )
                self.offset = max(0, raw.offset ?? 0)
                self.maximumResults = min(50, max(1, raw.maximumResults ?? (self.query == nil ? 20 : 8)))
            }

            public init(
                query: String? = nil,
                kinds: [CapabilityKind]? = nil,
                domains: [String]? = nil,
                visibility: CapabilityVisibility? = nil,
                risks: [ActionRisk]? = nil,
                offset: Int? = nil,
                maximumResults: Int? = nil
            ) {
                self.init(Raw(
                    query: query,
                    kinds: kinds,
                    domains: domains,
                    visibility: visibility,
                    risks: risks,
                    offset: offset,
                    maximumResults: maximumResults
                ))
            }

            public var raw: Raw {
                Raw(
                    query: query,
                    kinds: filter.kinds.isEmpty ? nil : filter.kinds,
                    domains: filter.domains.isEmpty ? nil : filter.domains,
                    visibility: filter.visibility,
                    risks: filter.risks.isEmpty ? nil : filter.risks,
                    offset: offset == 0 ? nil : offset,
                    maximumResults: maximumResults
                )
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            /// Every capability that matches, before paging.
            public let total: Int
            public let offset: Int
            /// True when a query ranked them, best first.
            public let ranked: Bool
            public let entries: [CapabilityEntry]

            public init(total: Int, offset: Int, ranked: Bool, entries: [CapabilityEntry]) {
                self.total = total
                self.offset = offset
                self.ranked = ranked
                self.entries = entries
            }
        }

        public static let purpose =
            "List or search the capabilities available to you: without a query, every one grouped by domain; with one, the matches best first. Narrow by kinds, domains, visibility or effect levels; page with offset. Changes nothing."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func call(_ input: Input, in context: CapabilityContext) async throws -> Output {
            let (snapshot, available) = try await CapabilityDiscovery.available(in: context)
            let filter = input.filter.resolvingDomains(context.catalog.domains)
            let primaryNames = context.catalog.domains.primaryNames
            let matches: [(inspection: CapabilityInspection, score: Int)] = available.compactMap { inspection in
                guard CapabilityKind(rawValue: inspection.kind) != nil,
                      filter.matches(inspection, visible: snapshot.visible),
                      let score = Self.score(inspection, query: input.query, domain: inspection.namespace.flatMap { primaryNames[$0] })
                else { return nil }
                return (inspection, score)
            }.sorted { lhs, rhs in
                // Ranked by score when searching; pages read as domains either way.
                if lhs.score != rhs.score { return lhs.score < rhs.score }
                if lhs.inspection.namespace != rhs.inspection.namespace {
                    return (lhs.inspection.namespace ?? "") < (rhs.inspection.namespace ?? "")
                }
                if lhs.inspection.kind != rhs.inspection.kind { return lhs.inspection.kind < rhs.inspection.kind }
                return lhs.inspection.identifier < rhs.inspection.identifier
            }
            let offset = min(matches.count, input.offset)
            let entries = matches.dropFirst(offset).prefix(input.maximumResults).compactMap { match -> CapabilityEntry? in
                guard let kind = CapabilityKind(rawValue: match.inspection.kind) else { return nil }
                let namespace = match.inspection.namespace
                return .init(
                    kind: kind,
                    identifier: match.inspection.identifier,
                    namespace: namespace.flatMap { primaryNames[$0] } ?? namespace,
                    purpose: match.inspection.purpose,
                    wasVisible: CapabilityDiscovery.contains(match.inspection.reference, in: snapshot.visible)
                )
            }
            return .init(total: matches.count, offset: offset, ranked: input.query != nil, entries: Array(entries))
        }

        public func render(_ output: Output, input: Input) -> String? {
            guard !output.entries.isEmpty else {
                if output.total == 0 {
                    return input.query == nil
                        ? "No available capabilities match."
                        : "No available capability matches. \(Self.identifier.rawValue) without a query lists them all."
                }
                return "Nothing from offset \(output.offset); \(output.total) in total."
            }
            let end = output.offset + output.entries.count
            let header = output.ranked
                ? "\(output.offset + 1)–\(end) of \(output.total) matches, best first:"
                : "\(output.offset + 1)–\(end) of \(output.total):"
            var text = header + "\n" + CapabilityEntry.rendered(output.entries)
            if end < output.total {
                var arguments = input.query.map { ["\"query\": \"\($0)\""] } ?? []
                arguments += input.filter.arguments + ["\"offset\": \(end)"]
                text += "\n\(Self.identifier.rawValue) {\(arguments.joined(separator: ", "))} continues."
            }
            return text + "\n\(Inspect.identifier.rawValue) returns a contract."
        }

        /// 0 for every entry when listing; when searching, lower is better
        /// and nil leaves it out.
        static func score(
            _ inspection: CapabilityInspection,
            query: String?,
            domain: String?
        ) -> Int? {
            guard let query else { return 0 }
            let identifier = inspection.identifier.lowercased()
            let name = (try? CapabilityIdentity(identifier))?.name.raw ?? identifier
            let domains = [inspection.namespace?.lowercased(), domain].compactMap { $0 }
            let purpose = inspection.purpose.lowercased()

            if identifier == query || name == query { return 0 }
            if name.hasPrefix(query) || identifier.hasSuffix(".\(query)") { return 1 }
            if identifier.contains(query) { return 2 }
            if domains.contains(where: { $0.contains(query) }) { return 3 }
            if purpose.contains(query) { return 4 }
            let searchable = ([identifier, purpose] + domains).joined(separator: " ")
            let terms = query.split(whereSeparator: \.isWhitespace)
            guard !terms.isEmpty, terms.allSatisfy({ searchable.contains($0) }) else { return nil }
            return 5
        }
    }
}
