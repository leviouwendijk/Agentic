import Agentic
import Workspace
import Foundation
import Primitives
import Search
import Schema
import Macros

public extension Standard.Tools {
    struct FindTools: Tool {
        @JSONSchema
        public struct Input: Source, Hashable {
            /// Natural-language capability or operation to search for.
            public let query: String

            /// Maximum number of matching tools to return and activate. Defaults to 5 and is capped at 8.
            public let maximumResults: Int?

            public init(
                query: String,
                maximumResults: Int? = nil
            ) {
                self.query = query
                self.maximumResults = maximumResults
            }

            public var resultLimit: Int {
                max(
                    1,
                    min(
                        maximumResults ?? 5,
                        8
                    )
                )
            }
        }

        @JSONSchema
        public struct Output: Result, Hashable {
            @JSONSchema
            public struct FoundTool:
                Sendable,
                Codable,
                Hashable
            {
                public let identifier: ToolIdentifier
                public let description: String
                public let risk: ActionRisk

                public init(
                    identifier: ToolIdentifier,
                    description: String,
                    risk: ActionRisk
                ) {
                    self.identifier = identifier
                    self.description = description
                    self.risk = risk
                }
            }

            public let query: String
            public let tools: [FoundTool]
            public let activated: [ToolIdentifier]

            public init(
                query: String,
                tools: [FoundTool],
                activated: [ToolIdentifier]
            ) {
                self.query = query
                self.tools = tools
                self.activated = activated
            }
        }

    public static let identifier: ToolIdentifier = "find_tools"
    public static let description = "Search the installed Agentic tool catalog by exact identifier or natural-language capability. Returned matches are exposed as native tools on subsequent model turns."
    public static let risk: ActionRisk = .observe
    public static let definition = ToolDefinition(
        identifier: identifier,
        purpose: description,
        risk: risk
    )

    public var identifier: ToolIdentifier {
        Self.identifier
    }

    public var description: String {
        Self.description
    }

    public var risk: ActionRisk {
        Self.risk
    }

    public let availability: any ToolAvailability
    public let exposure: any ToolExposure

    public init(
        availability: any ToolAvailability,
        exposure: any ToolExposure
    ) {
        self.availability = availability
        self.exposure = exposure
    }

    public func preflight(
        _ input: Input,
        workspace _: WorkspaceContext?
    ) async throws -> ToolPreflight {
        let query = try normalizedQuery(
            input.query
        )

        return ToolPreflight(
            tool: Self.definition.identifier,
            risk: Self.definition.risk,
            summary: "Find and activate up to \(input.resultLimit) installed tool(s) matching '\(query)'.",
            sideEffects: [
                "updates model-visible tool exposure for subsequent turns",
            ]
        )
    }

    public func call(
        _ input: Input,
        workspace _: WorkspaceContext?
    ) async throws -> Output {
        let query = try normalizedQuery(
            input.query
        )
        let definitions = availability
            .modelFacingDefinitions
            .filter {
                $0.identifier != Self.identifier
            }

        let exact = exactDefinition(
            for: query,
            in: definitions
        )
        let ranked = rankedDefinitions(
            for: query,
            in: definitions
        )

        var selected = [ToolDescriptor]()

        if let exact {
            selected.append(
                exact
            )
        }

        for definition in ranked
        where definition.identifier != exact?.identifier {
            guard selected.count < input.resultLimit else {
                break
            }

            selected.append(
                definition
            )
        }

        if selected.count > input.resultLimit {
            selected = Array(
                selected.prefix(
                    input.resultLimit
                )
            )
        }

        let tools = selected.map { definition in
            Output.FoundTool(
                identifier: definition.identifier,
                description: definition.description,
                risk: definition.risk
            )
        }

        let activated = try await exposure.activate(
            tools.map(\.identifier)
        )

        return Output(
            query: query,
            tools: tools,
            activated: activated
        )
    }
    }
}

private extension Standard.Tools.FindTools {
    struct SearchScore {
        var identifierScore = 0
        var descriptionScore = 0
        var matchedProbeIDs = Set<String>()

        var total: Int {
            identifierScore * 3
                + descriptionScore * 2
                + matchedProbeIDs.count * 100
        }
    }

    func exactDefinition(
        for query: String,
        in definitions: [ToolDescriptor]
    ) -> ToolDescriptor? {
        definitions.first { definition in
            definition.identifier.rawValue.compare(
                query,
                options: [
                    .caseInsensitive,
                ]
            ) == .orderedSame
        }
    }

    func rankedDefinitions(
        for query: String,
        in definitions: [ToolDescriptor]
    ) -> [ToolDescriptor] {
        let probes = searchProbes(
            for: query
        )

        guard !probes.isEmpty else {
            return []
        }

        let identifierCorpus = SearchCorpus(
            documents: definitions.map { definition in
                SearchDocument(
                    id: definition.identifier,
                    text: definition.identifier.rawValue
                )
            }
        )
        let descriptionCorpus = SearchCorpus(
            documents: definitions.map { definition in
                SearchDocument(
                    id: definition.identifier,
                    text: definition.description
                )
            }
        )
        let options = SearchOptions(
            mode: .ranked,
            strategy: .fuzzy,
            caseSensitive: false,
            minimumScore: 1,
            maximumResults: nil
        )
        let identifierResult = TextSearch.search(
            probes: probes,
            in: identifierCorpus,
            options: options
        )
        let descriptionResult = TextSearch.search(
            probes: probes,
            in: descriptionCorpus,
            options: options
        )

        var scores = [ToolIdentifier: SearchScore]()

        accumulate(
            identifierResult,
            field: .identifier,
            into: &scores
        )
        accumulate(
            descriptionResult,
            field: .description,
            into: &scores
        )

        return definitions
            .filter { definition in
                scores[definition.identifier] != nil
            }
            .sorted { lhs, rhs in
                let lhsScore = scores[lhs.identifier] ?? SearchScore()
                let rhsScore = scores[rhs.identifier] ?? SearchScore()

                if lhsScore.total != rhsScore.total {
                    return lhsScore.total > rhsScore.total
                }

                if lhsScore.matchedProbeIDs.count
                    != rhsScore.matchedProbeIDs.count {
                    return lhsScore.matchedProbeIDs.count
                        > rhsScore.matchedProbeIDs.count
                }

                if lhsScore.identifierScore
                    != rhsScore.identifierScore {
                    return lhsScore.identifierScore
                        > rhsScore.identifierScore
                }

                if lhsScore.descriptionScore
                    != rhsScore.descriptionScore {
                    return lhsScore.descriptionScore
                        > rhsScore.descriptionScore
                }

                return lhs.identifier.rawValue
                    < rhs.identifier.rawValue
            }
    }

    enum SearchField {
        case identifier
        case description
    }

    func accumulate(
        _ result: SearchResult<ToolIdentifier>,
        field: SearchField,
        into scores: inout [ToolIdentifier: SearchScore]
    ) {
        for hit in result.hits {
            var score = scores[hit.documentID]
                ?? SearchScore()

            switch field {
            case .identifier:
                score.identifierScore += hit.score.value

            case .description:
                score.descriptionScore += hit.score.value
            }

            score.matchedProbeIDs.formUnion(
                hit.evidence.compactMap(\.queryID)
            )

            scores[hit.documentID] = score
        }
    }

    func searchProbes(
        for query: String
    ) -> [SearchProbe] {
        let terms = capabilityTerms(
            in: query
        )

        guard !terms.isEmpty else {
            return []
        }

        var probes = [
            SearchProbe(
                query,
                id: "query",
                weight: 3,
                role: .preferred,
                strategy: .fuzzy
            ),
        ]

        for term in terms {
            probes.append(
                SearchProbe(
                    term,
                    id: "term:\(term)",
                    weight: 1,
                    role: .preferred,
                    strategy: .fuzzy
                )
            )
        }

        return probes
    }

    func capabilityTerms(
        in value: String
    ) -> [String] {
        let ignoredTerms: Set<String> = [
            "and",
            "can",
            "could",
            "find",
            "help",
            "need",
            "please",
            "that",
            "the",
            "this",
            "tool",
            "tools",
            "use",
            "want",
            "with",
            "you",
        ]
        var seen = Set<String>()

        return normalizedTerms(
            in: value
        ).filter { term in
            guard term.count >= 3,
                  !ignoredTerms.contains(term),
                  !seen.contains(term)
            else {
                return false
            }

            seen.insert(
                term
            )
            return true
        }
    }

    func normalizedTerms(
        in value: String
    ) -> [String] {
        value
            .lowercased()
            .split { character in
                !character.isLetter
                    && !character.isNumber
            }
            .map(String.init)
            .map { term in
                if term.count > 4,
                   term.hasSuffix("ies") {
                    return String(
                        term.dropLast(3)
                    ) + "y"
                }

                return term
            }
    }

    func normalizedQuery(
        _ query: String
    ) throws -> String {
        let query = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !query.isEmpty else {
            throw FindToolsError.emptyQuery
        }

        return query
    }
}
