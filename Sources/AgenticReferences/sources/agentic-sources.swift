import Primitives
import References

public enum AgenticSources {
    public static var all: [any AgenticSourceProviding] {
        boxed(Harness.self)
            + boxed(Context.self)
            + boxed(Routing.self)
    }

    public static var collection: ReferenceCollection {
        ReferenceCollection(
            all.map {
                $0 as any ReferenceProviding
            }
        )
    }

    public static func section(
        _ section: ReferenceTagSection
    ) -> [any AgenticSourceProviding] {
        collection
            .section(section)
            .compactMap {
                $0 as? any AgenticSourceProviding
            }
    }

    public static func tagged(
        _ tag: AgenticTag
    ) -> [any AgenticSourceProviding] {
        matching(
            tags: [tag]
        )
    }

    public static func matching(
        tags: [AgenticTag],
        match: ReferenceTagMatch = .any
    ) -> [any AgenticSourceProviding] {
        collection
            .matching(
                tags: tags.map(\.tag),
                match: match
            )
            .compactMap {
                $0 as? any AgenticSourceProviding
            }
    }

    public static func boxed<Source: AgenticSourceProviding>(
        _ source: Source.Type
    ) -> [any AgenticSourceProviding] {
        Source.allCases.map {
            $0 as any AgenticSourceProviding
        }
    }

    static func authors(
        _ values: [ReferenceAuthor],
        original: String? = nil
    ) -> ReferenceAuthors {
        ReferenceAuthors(
            values,
            original: original
        )
    }

    static func author(
        given: String,
        family: String,
        original: String? = nil
    ) -> ReferenceAuthor {
        ReferenceAuthor.person(
            given: given,
            family: family,
            original: original
        )
    }
}

extension AgenticSources {
    static func entry(
        title: String,
        location: ReferenceURL,
        source: ReferenceSource? = nil,
        authors: ReferenceAuthors? = nil,
        date: PartialDate? = nil,
        container: ReferenceContainer? = nil,
        doi: String? = nil,
        kind: ReferenceKind = .article,
        channel: ReferenceChannel = .peer_reviewed,
        abstract: ReferenceTextBlock? = nil,
        notes: [ReferenceTextBlock] = [],
        reviews: [ReferenceReview] = [],
        relations: [ReferenceRelation] = [],
        tags: ReferenceTagSet
    ) -> ReferenceData {
        ReferenceData(
            title: title,
            location: location,
            source: source ?? inferred_source(
                location: location,
                doi: doi
            ),
            authors: authors,
            date: date,
            container: container,
            doi: doi,
            kind: kind,
            channel: channel,
            abstract: abstract,
            notes: notes,
            reviews: reviews,
            relations: relations,
            tags: tags
        )
    }

    /// arXiv preprint entry; location, source, container and kind follow from the identifier.
    static func arxiv(
        _ id: String,
        title: String,
        authors: ReferenceAuthors? = nil,
        date: PartialDate? = nil,
        abstract: ReferenceTextBlock? = nil,
        notes: [ReferenceTextBlock] = [],
        reviews: [ReferenceReview] = [],
        relations: [ReferenceRelation] = [],
        tags: ReferenceTagSet
    ) -> ReferenceData {
        entry(
            title: title,
            location: arxiv_location(id),
            source: .arxiv,
            authors: authors,
            date: date,
            container: ReferenceContainer(
                kind: .repository,
                title: "arXiv",
                publisher: "Cornell University"
            ),
            kind: .preprint,
            channel: .preprint,
            abstract: abstract,
            notes: notes,
            reviews: reviews,
            relations: relations,
            tags: tags
        )
    }

    static func arxiv_location(
        _ id: String
    ) -> ReferenceURL {
        ReferenceSource.arxiv.url("abs", id)
    }

    static func doi_location(
        _ doi: String
    ) -> ReferenceURL {
        ReferenceSource.doi.url(doi)
    }

    static func web_location(
        _ url: String
    ) -> ReferenceURL {
        ReferenceURL.web(url)
    }

    static func published(
        _ iso8601: String
    ) -> PartialDate? {
        try? PartialDate.iso8601(iso8601)
    }

    static func authors(
        _ original: String
    ) -> ReferenceAuthors {
        ReferenceAuthors(
            original: original
        )
    }

    private static func inferred_source(
        location: ReferenceURL,
        doi: String?
    ) -> ReferenceSource? {
        if doi != nil {
            return .doi
        }

        return ReferenceSource(
            url: location
        )
    }
}
