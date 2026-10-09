import Agentic
import Foundation
import Macros
import Schema

public enum FindCapabilitiesError:
    Error,
    Sendable
{
    case agentCapabilityStateRequired
}

public extension Standard.Tools {
    @Tool
    struct FindCapabilities: Tool {
        public enum Kind:
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

        @JSONSchema
        public struct Input:
            Sendable,
            Codable,
            Hashable
        {
            public let query: String?
            public let kind: Kind?
            public let domain: String?
            public let maximumResults: Int?

            public init(
                query: String? = nil,
                kind: Kind? = nil,
                domain: String? = nil,
                maximumResults: Int? = nil
            ) {
                self.query = query
                self.kind = kind
                self.domain = domain
                self.maximumResults = maximumResults
            }

            var resolvedKind: Kind {
                kind ?? .all
            }

            var resolvedMaximumResults: Int {
                min(
                    8,
                    max(
                        1,
                        maximumResults ?? 5
                    )
                )
            }
        }

        @JSONSchema
        public struct Entry:
            Sendable,
            Codable,
            Hashable
        {
            public let kind: Kind
            public let identifier: String
            public let namespace: String?
            public let purpose: String
            public let wasVisible: Bool
            public let revealed: Bool

            public init(
                kind: Kind,
                identifier: String,
                namespace: String?,
                purpose: String,
                wasVisible: Bool,
                revealed: Bool
            ) {
                self.kind = kind
                self.identifier = identifier
                self.namespace = namespace
                self.purpose = purpose
                self.wasVisible = wasVisible
                self.revealed = revealed
            }
        }

        @JSONSchema
        public struct Output:
            Sendable,
            Codable,
            Hashable
        {
            public let totalMatches: Int
            public let returnedCount: Int
            public let entries: [Entry]

            public init(
                totalMatches: Int,
                returnedCount: Int,
                entries: [Entry]
            ) {
                self.totalMatches = totalMatches
                self.returnedCount = returnedCount
                self.entries = entries
            }
        }

        public static let purpose =
            "Search capabilities already available to the current Agent and reveal the selected matches without granting new authority."

        public static let risk: ActionRisk = .observe

        public init() {}

        public func call(
            _ input: Input,
            in context: ToolContext
        ) async throws -> Output {
            guard let capabilities = context.capabilities else {
                throw FindCapabilitiesError
                    .agentCapabilityStateRequired
            }

            let before = await capabilities.snapshot()
            let query = normalized(
                input.query
            )
            let domain = normalized(
                input.domain
            )
            let candidates = context.catalog.entries
                .compactMap { entry in
                    candidate(
                        entry,
                        available: before.available,
                        kind: input.resolvedKind,
                        domain: domain,
                        query: query
                    )
                }
                .sorted(by: candidatePrecedes)
            let selected = Array(
                candidates.prefix(
                    input.resolvedMaximumResults
                )
            )
            let requested = capabilitySet(
                for: selected
            )
            let revealed = await capabilities.reveal(
                requested
            )

            return Output(
                totalMatches: candidates.count,
                returnedCount: selected.count,
                entries: selected.map { candidate in
                    Entry(
                        kind: candidate.kind,
                        identifier: candidate.identifier,
                        namespace: candidate.namespace,
                        purpose: candidate.purpose,
                        wasVisible: contains(
                            candidate,
                            in: before.visible
                        ),
                        revealed: contains(
                            candidate,
                            in: revealed
                        )
                    )
                }
            )
        }
    }
}

private extension Standard.Tools.FindCapabilities {
    struct Candidate {
        let kind: Kind
        let identifier: String
        let namespace: String?
        let purpose: String
        let score: Int
    }

    func candidate(
        _ entry: Catalog.Entry,
        available: AgentCapabilitySet,
        kind: Kind,
        domain: String?,
        query: String?
    ) -> Candidate? {
        guard let candidate = candidate(
            entry
        ) else {
            return nil
        }

        guard kind == .all || candidate.kind == kind else {
            return nil
        }

        if let domain,
           candidate.namespace?.lowercased() != domain {
            return nil
        }

        guard contains(
            candidate,
            in: available
        ) else {
            return nil
        }

        guard let score = matchScore(
            candidate,
            query: query
        ) else {
            return nil
        }

        return Candidate(
            kind: candidate.kind,
            identifier: candidate.identifier,
            namespace: candidate.namespace,
            purpose: candidate.purpose,
            score: score
        )
    }

    func candidate(
        _ entry: Catalog.Entry
    ) -> Candidate? {
        let namespace =
            entry.namespace?.rawValue

        switch entry.declaration {
        case .tool(let definition):
            return .init(
                kind: .tool,
                identifier: definition.identifier.rawValue,
                namespace: namespace,
                purpose: definition.purpose,
                score: 0
            )

        case .program(let definition):
            return .init(
                kind: .program,
                identifier: definition.identifier.rawValue,
                namespace: namespace,
                purpose: definition.purpose,
                score: 0
            )

        case .inference(let definition):
            return .init(
                kind: .inference,
                identifier: definition.identifier.rawValue,
                namespace: namespace,
                purpose: definition.purpose,
                score: 0
            )

        case .agent(let definition):
            return .init(
                kind: .agent,
                identifier: definition.identifier.rawValue,
                namespace: namespace,
                purpose: definition.purpose,
                score: 0
            )

        case .adapter:
            // Adapters are inference infrastructure, not Agent capabilities.
            return nil
        }
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
        case .all:
            return false

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

    func capabilitySet(
        for candidates: [Candidate]
    ) -> AgentCapabilitySet {
        .init(
            tools: candidates.compactMap { candidate in
                guard candidate.kind == .tool else {
                    return nil
                }

                return ToolIdentifier(
                    rawValue: candidate.identifier
                )
            },
            programs: candidates.compactMap { candidate in
                guard candidate.kind == .program else {
                    return nil
                }

                return ProgramIdentifier(
                    rawValue: candidate.identifier
                )
            },
            inferences: candidates.compactMap { candidate in
                guard candidate.kind == .inference else {
                    return nil
                }

                return InferenceIdentifier(
                    rawValue: candidate.identifier
                )
            },
            agents: candidates.compactMap { candidate in
                guard candidate.kind == .agent else {
                    return nil
                }

                return AgentIdentifier(
                    rawValue: candidate.identifier
                )
            }
        )
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
