
extension ModelSelectionResolver {
    public enum Source:
        String,
        Sendable,
        Codable,
        Hashable,
        CaseIterable
    {
        case application_default
        case mode_default
        case agent
        case optimized_realization
        case session
        case task
        case user
    }

    public struct Contribution:
        Sendable,
        Codable,
        Hashable
    {
        public var source: ModelSelectionResolver.Source
        public var selection: AgentModelSelection
        public var metadata: [String: String]

        public init(
            source: ModelSelectionResolver.Source,
            selection: AgentModelSelection,
            metadata: [String: String] = [:]
        ) {
            self.source = source
            self.selection = selection
            self.metadata = metadata
        }
    }

    public struct Resolution:
        Sendable,
        Codable,
        Hashable
    {
        public var selection: AgentModelSelection
        public var diagnostics: [AgentModelSelectionDiagnostic]

        public init(
            selection: AgentModelSelection,
            diagnostics: [AgentModelSelectionDiagnostic] = []
        ) {
            self.selection = selection
            self.diagnostics = diagnostics
        }
    }

    public enum Failure:
        Error,
        Sendable,
        Hashable
    {
        case empty_contributions
        case conflicting_purpose(
            expected: AgentModelRoutePurpose,
            actual: AgentModelRoutePurpose,
            source: ModelSelectionResolver.Source
        )
    }
}

public struct ModelSelectionResolver: Sendable {
    public let precedence: ModelSelectionPrecedence

    public init(
        precedence: ModelSelectionPrecedence = .default
    ) {
        self.precedence = precedence
    }

    public func resolve(
        _ selection: AgentModelSelection
    ) throws -> ModelSelectionResolver.Resolution {
        .init(
            selection: selection
        )
    }

    public func resolve(
        _ contributions: [ModelSelectionResolver.Contribution]
    ) throws -> ModelSelectionResolver.Resolution {
        guard !contributions.isEmpty else {
            throw ModelSelectionResolver.Failure
                .empty_contributions
        }

        let ordered = contributions
            .enumerated()
            .sorted { lhs, rhs in
                let lhsPrecedence = precedence.rank(
                    of: lhs.element.source
                )
                let rhsPrecedence = precedence.rank(
                    of: rhs.element.source
                )

                if lhsPrecedence != rhsPrecedence {
                    return lhsPrecedence < rhsPrecedence
                }

                return lhs.offset < rhs.offset
            }
            .map { element in
                element.element
            }

        let purpose = ordered[0].selection.purpose
        let operation = ordered[ordered.count - 1].selection.operation
        var requirements = AgentModelRequirements(
            capabilities: []
        )
        var preferences = AgentModelPreferences()
        var constraints = AgentModelConstraints()
        var metadata: [String: String] = [:]

        for contribution in ordered {
            guard contribution.selection.purpose == purpose else {
                throw ModelSelectionResolver.Failure
                    .conflicting_purpose(
                        expected: purpose,
                        actual: contribution.selection.purpose,
                        source: contribution.source
                    )
            }

            requirements = requirements.merging(
                contribution.selection.requirements
            )
            preferences = preferences.overriding(
                with: contribution.selection.preferences
            )
            constraints = constraints.tightened(
                by: contribution.selection.constraints
            )

            metadata.merge(
                contribution.selection.metadata
            ) { _, new in
                new
            }
            metadata.merge(
                contribution.metadata
            ) { _, new in
                new
            }
        }

        return .init(
            selection: .init(
                purpose: purpose,
                operation: operation,
                requirements: requirements,
                preferences: preferences,
                constraints: constraints,
                metadata: metadata
            )
        )
    }
}

