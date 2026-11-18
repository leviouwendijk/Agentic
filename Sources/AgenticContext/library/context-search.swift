import Foundation
import Search

public extension Context {
    /// The parts of an entry search looks in.
    enum Field: String, Sendable, Hashable, Codable, CaseIterable {
        case title
        case summary
        case tags
        case body

        /// A match here counts this many times: what an entry is about
        /// outweighs a passing mention in its body.
        var weight: Int {
            switch self {
            case .title: 4
            case .summary: 3
            case .tags: 3
            case .body: 1
            }
        }
    }

    struct SearchMatch: Sendable, Hashable {
        public struct Line: Sendable, Hashable {
            /// From the body's first line.
            public let number: Int
            public let text: String
        }

        public let item: Library.Item
        public let score: Int
        public let fields: [Field]
        /// Body lines that matched.
        public let lines: [Line]
    }

    /// One field of one entry, as a search document.
    internal struct FieldDocument: Hashable, Sendable {
        let id: String
        let field: Field
    }
}

public extension Context.Library {
    /// Ranks entries by `queries` over their typed fields with the Search
    /// library: one document per entry field, scores summed per entry and
    /// weighted by field.
    func search(
        _ queries: [String],
        in items: [Item]? = nil,
        fields: [Context.Field] = Context.Field.allCases,
        /// Fuzzy when nil.
        strategy: SearchStrategy? = nil,
        limit: Int = 10
    ) -> [Context.SearchMatch] {
        let queries = queries.map { SearchQuery($0) }.filter { !$0.isEmpty }
        guard !queries.isEmpty else { return [] }
        let items = items ?? self.items
        let wanted = Set(fields)
        var documents: [SearchDocument<Context.FieldDocument>] = []
        for item in items {
            for field in Context.Field.allCases where wanted.contains(field) {
                let text: String
                switch field {
                case .title: text = item.entry.title
                case .summary: text = item.entry.summary
                case .tags: text = (item.entry.tags ?? []).joined(separator: "\n")
                case .body: text = item.entry.body
                }
                guard !text.isEmpty else { continue }
                documents.append(.init(id: .init(id: item.id, field: field), text: text))
            }
        }
        var options = SearchOptions(maximumResults: nil)
        if let strategy {
            options.strategy = strategy
        }
        let result = TextSearch.search(
            queries,
            in: SearchCorpus(documents: documents),
            options: options
        )

        var scores: [String: Int] = [:]
        var matched: [String: Set<Context.Field>] = [:]
        var lines: [String: Set<Int>] = [:]
        for hit in result.hits {
            let document = hit.documentID
            scores[document.id, default: 0] += hit.score.value * document.field.weight
            matched[document.id, default: []].insert(document.field)
            if document.field == .body {
                for range in hit.lineRanges {
                    lines[document.id, default: []].formUnion(range.start...max(range.start, range.end))
                }
            }
        }
        let ranked = items
            .filter { scores[$0.id] != nil }
            .sorted { (scores[$0.id] ?? 0, $1.id) > (scores[$1.id] ?? 0, $0.id) }
            .prefix(max(0, limit))
        return ranked.map { item in
            let body = item.entry.body.split(separator: "\n", omittingEmptySubsequences: false)
            let numbers = (lines[item.id] ?? []).sorted().filter { $0 >= 1 && $0 <= body.count }
            return .init(
                item: item,
                score: scores[item.id] ?? 0,
                fields: Context.Field.allCases.filter { matched[item.id]?.contains($0) == true },
                lines: numbers.prefix(8).map { .init(number: $0, text: String(body[$0 - 1])) }
            )
        }
    }
}
