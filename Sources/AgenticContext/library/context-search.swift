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

    /// One search term and what it does to an entry.
    struct Probe: Sendable, Hashable {
        public enum Role: String, Sendable, Hashable, Codable, CaseIterable {
            /// Every entry returned matches it.
            case required
            /// Ranks entries that match it higher.
            case preferred
            /// No entry returned matches it.
            case excluded
        }

        public let text: String
        public let role: Role
        /// The search's own when nil.
        public let strategy: SearchStrategy?

        public init(_ text: String, role: Role = .preferred, strategy: SearchStrategy? = nil) {
            self.text = text
            self.role = role
            self.strategy = strategy
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

    struct SearchResult: Sendable, Hashable {
        /// This page, best first.
        public let matches: [SearchMatch]
        /// Every entry admitted, before paging.
        public let total: Int
    }

    enum SearchFailure: Error, LocalizedError, Sendable, Hashable {
        case unknownField(String)
        case nothingToFind

        public var errorDescription: String? {
            switch self {
            case .unknownField(let name):
                return "'\(name)' is not a field; search title, summary, tags or body."
            case .nothingToFind:
                return "Give at least one query, or a required or preferred probe; excluded probes only narrow."
            }
        }
    }

    /// One field of one entry, as a search document.
    internal struct FieldDocument: Hashable, Sendable {
        let id: String
        let field: Field
    }
}

public extension Context.Library {
    /// Ranks `items` (the whole library when nil) by `probes` over their
    /// typed fields with the Search library. Roles hold per entry: a
    /// required term may match the title and another the body.
    func search(
        _ probes: [Context.Probe],
        in items: [Item]? = nil,
        fields: [Context.Field] = Context.Field.allCases,
        strategy: SearchStrategy? = nil,
        caseSensitive: Bool = false,
        limit: Int = 10,
        offset: Int = 0
    ) throws -> Context.SearchResult {
        let probes = probes.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard probes.contains(where: { $0.role != .excluded }) else {
            throw Context.SearchFailure.nothingToFind
        }
        let items = items ?? self.items
        let corpus = SearchCorpus(documents: Self.documents(items, fields: Set(fields)))

        var scores: [String: Int] = [:]
        var matched: [String: Set<Context.Field>] = [:]
        var lines: [String: Set<Int>] = [:]
        var admitted = Set(items.map(\.id))
        var positive: Set<String> = []
        for probe in probes {
            var options = SearchOptions(caseSensitive: caseSensitive, maximumResults: nil)
            if let chosen = probe.strategy ?? strategy {
                options.strategy = chosen
            }
            let hits = TextSearch.search([SearchQuery(probe.text)], in: corpus, options: options).hits
            let entries = Set(hits.map(\.documentID.id))
            switch probe.role {
            case .excluded:
                admitted.subtract(entries)
                continue
            case .required:
                admitted.formIntersection(entries)
            case .preferred:
                break
            }
            positive.formUnion(entries)
            for hit in hits {
                let document = hit.documentID
                scores[document.id, default: 0] += hit.score.value * document.field.weight
                matched[document.id, default: []].insert(document.field)
                if document.field == .body {
                    for range in hit.lineRanges {
                        lines[document.id, default: []].formUnion(range.start...max(range.start, range.end))
                    }
                }
            }
        }

        let ranked = items
            .filter { admitted.contains($0.id) && positive.contains($0.id) }
            .sorted { (scores[$0.id] ?? 0, $1.id) > (scores[$1.id] ?? 0, $0.id) }
        let page = ranked.dropFirst(max(0, offset)).prefix(max(0, limit))
        return .init(
            matches: page.map { item in
                let body = item.entry.body.split(separator: "\n", omittingEmptySubsequences: false)
                let numbers = (lines[item.id] ?? []).sorted().filter { $0 >= 1 && $0 <= body.count }
                return .init(
                    item: item,
                    score: scores[item.id] ?? 0,
                    fields: Context.Field.allCases.filter { matched[item.id]?.contains($0) == true },
                    lines: numbers.prefix(8).map { .init(number: $0, text: String(body[$0 - 1])) }
                )
            },
            total: ranked.count
        )
    }

    private static func documents(
        _ items: [Item],
        fields: Set<Context.Field>
    ) -> [SearchDocument<Context.FieldDocument>] {
        var documents: [SearchDocument<Context.FieldDocument>] = []
        for item in items {
            for field in Context.Field.allCases where fields.contains(field) {
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
        return documents
    }
}
