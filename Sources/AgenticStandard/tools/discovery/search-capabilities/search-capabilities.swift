import Agentic
import Foundation
import Macros
import Schema
import Primitives

public extension Standard.Tools {
    @Tool
    struct SearchCapabilities: Tool {
        public struct Input: HashableSource, CodableInvariant {
            @JSONSchema
            public struct Raw: HashableSource {
                public var query: String?
                /// Any of these kinds; all when omitted.
                public var kinds: [CapabilityKind]?
                /// Any of these domains (namespaces).
                public var domains: [String]?
                /// Only those among your tools (`visible`) or only the others.
                public var visibility: CapabilityVisibility?
                /// Any of these effect levels; capabilities without one do not match.
                public var risks: [ActionRisk]?
                /// Defaults to 5; clamped to 1...8.
                public var maximumResults: Int?

                public init(
                    query: String? = nil,
                    kinds: [CapabilityKind]? = nil,
                    domains: [String]? = nil,
                    visibility: CapabilityVisibility? = nil,
                    risks: [ActionRisk]? = nil,
                    maximumResults: Int? = nil
                ) {
                    self.query = query
                    self.kinds = kinds
                    self.domains = domains
                    self.visibility = visibility
                    self.risks = risks
                    self.maximumResults = maximumResults
                }
            }

            public let query: String?
            public let filter: CapabilityFilter
            public let maximumResults: Int

            public init(_ raw: Raw) {
                self.query = raw.query
                self.filter = .init(
                    kinds: raw.kinds,
                    domains: raw.domains,
                    visibility: raw.visibility,
                    risks: raw.risks
                )
                self.maximumResults = min(8, max(1, raw.maximumResults ?? 5))
            }

            public init(
                query: String? = nil,
                kinds: [CapabilityKind]? = nil,
                domains: [String]? = nil,
                visibility: CapabilityVisibility? = nil,
                risks: [ActionRisk]? = nil,
                maximumResults: Int? = nil
            ) {
                self.init(
                    Raw(
                        query: query,
                        kinds: kinds,
                        domains: domains,
                        visibility: visibility,
                        risks: risks,
                        maximumResults: maximumResults
                    )
                )
            }

            public var raw: Raw {
                Raw(
                    query: query,
                    kinds: filter.kinds.isEmpty ? nil : filter.kinds,
                    domains: filter.domains.isEmpty ? nil : filter.domains,
                    visibility: filter.visibility,
                    risks: filter.risks.isEmpty ? nil : filter.risks,
                    maximumResults: maximumResults
                )
            }
        }

        @JSONSchema
        public struct Output: HashableResult
        {
            public let totalMatches: Int
            public let returnedCount: Int
            public let entries: [CapabilityEntry]

            public init(
                totalMatches: Int,
                returnedCount: Int,
                entries: [CapabilityEntry]
            ) {
                self.totalMatches = totalMatches
                self.returnedCount = returnedCount
                self.entries = entries
            }
        }

        public static let purpose =
            "Search the capabilities available to this Agent by query, narrowed by kinds, domains, visibility or effect levels, without changing authorization or model projection."

        public static let risk: ActionRisk = .observe

        public init() {}

        public func call(
            _ input: Input,
            in context: ToolContext
        ) async throws -> Output {
            guard let capabilities = context.capabilities else {
                throw CapabilityDiscoveryError
                    .agentCapabilityStateRequired
            }

            let before = await capabilities.snapshot()
            let query = normalized(
                input.query
            )
            let candidates = context.inspections
                .compactMap { inspection in
                    candidate(
                        inspection,
                        available: before.available.intersecting(before.installed),
                        filter: input.filter,
                        visible: before.visible,
                        query: query
                    )
                }
                .sorted(by: candidatePrecedes)
            let selected = Array(
                candidates.prefix(
                    input.maximumResults
                )
            )
            return Output(
                totalMatches: candidates.count,
                returnedCount: selected.count,
                entries: selected.map { candidate in
                    CapabilityEntry(
                        kind: candidate.kind,
                        identifier: candidate.identifier,
                        namespace: candidate.namespace,
                        purpose: candidate.purpose,
                        wasVisible: contains(
                            candidate,
                            in: before.visible
                        )
                    )
                }
            )
        }

        public func render(_ output: Output, input: Input) -> String? {
            guard !output.entries.isEmpty else {
                return "No available capability matches. list_capabilities shows them all."
            }
            let header = output.returnedCount < output.totalMatches
                ? "\(output.returnedCount) of \(output.totalMatches) matches, best first:"
                : "\(output.totalMatches) match\(output.totalMatches == 1 ? "" : "es"):"
            return header + "\n" + CapabilityEntry.rendered(output.entries)
                + "\ninspect_capability returns a contract."
        }
    }
}

private extension Standard.Tools.SearchCapabilities {
    struct Candidate {
        let kind: CapabilityKind
        let identifier: String
        let namespace: String?
        let purpose: String
        let score: Int
    }

    func candidate(
        _ inspection: CapabilityInspection,
        available: AgentCapabilitySet,
        filter: CapabilityFilter,
        visible: AgentCapabilitySet,
        query: String?
    ) -> Candidate? {
        guard let resolvedKind = CapabilityKind(rawValue: inspection.kind),
              filter.matches(inspection, visible: visible) else { return nil }
        guard CapabilityDiscovery.contains(inspection.reference, in: available) else {
            return nil
        }
        let candidate = Candidate(
            kind: resolvedKind,
            identifier: inspection.identifier,
            namespace: inspection.namespace,
            purpose: inspection.purpose,
            score: 0
        )
        guard let score = matchScore(candidate, query: query) else { return nil }
        return Candidate(
            kind: resolvedKind,
            identifier: inspection.identifier,
            namespace: inspection.namespace,
            purpose: inspection.purpose,
            score: score
        )
    }

    func matchScore(
        _ candidate: Candidate,
        query: String?
    ) -> Int? {
        guard let query else {
            return 0
        }

        let identifier =
            candidate.identifier.lowercased()
        let namespace =
            candidate.namespace?.lowercased()
            ?? ""
        let purpose =
            candidate.purpose.lowercased()

        if identifier == query {
            return 0
        }

        if identifier.hasSuffix(
            ".\(query)"
        ) {
            return 1
        }

        if identifier.contains(
            query
        ) {
            return 2
        }

        if namespace.contains(
            query
        ) {
            return 3
        }

        if purpose.contains(
            query
        ) {
            return 4
        }

        let searchable =
            "\(identifier) \(namespace) \(purpose)"
        let terms = query.split(
            whereSeparator: \.isWhitespace
        )

        guard !terms.isEmpty,
              terms.allSatisfy({
                  searchable.contains(
                      $0
                  )
              })
        else {
            return nil
        }

        return 5
    }

    func candidatePrecedes(
        _ lhs: Candidate,
        _ rhs: Candidate
    ) -> Bool {
        if lhs.score != rhs.score {
            return lhs.score < rhs.score
        }

        if lhs.namespace != rhs.namespace {
            return (lhs.namespace ?? "")
                < (rhs.namespace ?? "")
        }

        if lhs.kind.rawValue != rhs.kind.rawValue {
            return lhs.kind.rawValue
                < rhs.kind.rawValue
        }

        return lhs.identifier
            < rhs.identifier
    }

    func contains(
        _ candidate: Candidate,
        in capabilities: AgentCapabilitySet
    ) -> Bool {
        switch candidate.kind {
        case .tool:
            return capabilities.tools.contains(
                ToolIdentifier(
                    rawValue: candidate.identifier
                )
            )

        case .program:
            return capabilities.programs.contains(
                ProgramIdentifier(
                    rawValue: candidate.identifier
                )
            )

        case .inference:
            return capabilities.inferences.contains(
                InferenceIdentifier(
                    rawValue: candidate.identifier
                )
            )

        case .agent:
            return capabilities.agents.contains(
                AgentIdentifier(
                    rawValue: candidate.identifier
                )
            )
        }
    }

    func normalized(
        _ value: String?
    ) -> String? {
        guard let value else {
            return nil
        }

        let normalized = value
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()

        return normalized.isEmpty
            ? nil
            : normalized
    }
}
