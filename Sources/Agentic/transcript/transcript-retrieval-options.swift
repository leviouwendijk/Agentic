import Fuzzy
import Ranking
import Tokens

public struct TranscriptRetrievalOptions: Sendable, Codable, Hashable {
    public var tokenNormalization: TokenNormalizationOptions
    public var fuzzy: FuzzyOptions
    public var selection: RankingSelectionOptions

    public init(
        tokenNormalization: TokenNormalizationOptions = .defaults,
        fuzzy: FuzzyOptions = .defaults,
        selection: RankingSelectionOptions = .init(
            order: .descending,
            threshold: .minimum(1),
            limit: 8
        )
    ) {
        self.tokenNormalization = tokenNormalization
        self.fuzzy = fuzzy
        self.selection = selection
    }

    public static let `default` = Self()
}
