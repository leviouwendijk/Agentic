public struct ModelSelectionPrecedence: Sendable, Codable, Hashable {
    public typealias Source = ModelSelectionResolver.Source

    /// Ordered from lowest to highest authority.
    public let sources: [Source]

    public enum Failure: Error, Sendable, Hashable {
        case incomplete_or_duplicate_sources
    }

    public init(sources: [Source]) throws {
        guard Set(sources).count == sources.count,
              Set(sources) == Set(Source.allCases)
        else {
            throw Failure.incomplete_or_duplicate_sources
        }

        self.sources = sources
    }

    private init(knownValid sources: [Source]) {
        self.sources = sources
    }

    public static let `default` = Self(knownValid: [
        .application_default,
        .mode_default,
        .agent,
        .optimized_realization,
        .task,
        .session,
        .user
    ])

    public func rank(of source: Source) -> Int {
        // The initializer and built-in default guarantee total coverage.
        sources.firstIndex(of: source) ?? -1
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(sources: container.decode([Source].self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(sources)
    }
}
