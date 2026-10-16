import Agentic
import Foundation

public enum ContextFindingError: Error, Sendable, Equatable {
    case invalidRecord(String)
    case invalidResolution(String)
}

public extension Context {
    /// An index of addressable facts, NOT storage for transcript or artifact data.
    /// Retrieval authority and materialization remain with RecordResolving.
    struct FindingIndex: Sendable, Codable, Hashable {
        public struct Entry: Sendable, Codable, Hashable {
            public let record: Record
            public let terms: [String]

            public init(record: Record, terms: [String]) {
                self.record = record
                self.terms = terms
            }
        }

        public let entries: [Entry]

        public init(_ entries: [Entry]) throws {
            var seen: Set<String> = []
            for entry in entries {
                let references = [entry.record.pointer] + entry.record.derivedFrom
                guard !entry.record.id.isEmpty,
                    entry.record.id.count <= 160,
                    entry.record.kind == "finding",
                    !entry.record.derivedFrom.isEmpty,
                    !entry.terms.isEmpty,
                    entry.terms.count <= 32,
                    entry.terms.allSatisfy({ !$0.isEmpty && $0.count <= 128 }),
                    seen.insert(entry.record.id).inserted,
                    references.allSatisfy({ pointer in
                        guard !pointer.source.isEmpty, !pointer.record.isEmpty else { return false }
                        if case .recorded(let revision) = pointer.revision {
                            return !revision.isEmpty
                        }
                        return false
                    }) else {
                    throw ContextFindingError.invalidRecord(entry.record.id)
                }
            }
            self.entries = entries
        }

        /// Stable deterministic relevance ordering. This is a candidate filter,
        /// never an assertion that a record is true or that it may be read.
        public func candidates(for query: String, maximum: Int) -> [Entry] {
            guard maximum > 0 else { return [] }
            let terms = Set(Self.words(query))
            guard !terms.isEmpty else { return [] }
            return entries.compactMap { entry -> (entry: Entry, score: Int)? in
                let entryTerms = Set(entry.terms.flatMap(Self.words))
                let score = terms.intersection(entryTerms).count
                return score > 0 ? (entry, score) : nil
            }.sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.entry.record.id < rhs.entry.record.id
            }.prefix(maximum).map(\.entry)
        }

        /// Check both finding revision and original evidence revisions before
        /// proposing allocations. Stale records are excluded, not substituted.
        /// Resolver errors (including unauthorized sources) propagate fail-closed.
        public func eligible(
            for query: String,
            maximum: Int,
            using resolver: any RecordResolving
        ) async throws -> [Entry] {
            var valid: [Entry] = []
            for entry in candidates(for: query, maximum: maximum) {
                let references = [entry.record.pointer] + entry.record.derivedFrom
                var current = true
                for expected in references {
                    let latest = Pointer(
                        source: expected.source,
                        record: expected.record,
                        selection: expected.selection,
                        revision: .latest
                    )
                    let observation = try await resolver.resolve(latest)
                    guard observation.pointer.source == expected.source,
                        observation.pointer.record == expected.record,
                        observation.pointer.selection == expected.selection,
                        case .recorded = observation.pointer.revision else {
                        throw ContextFindingError.invalidResolution(entry.record.id)
                    }
                    if observation.pointer.revision != expected.revision {
                        current = false
                        break
                    }
                }
                if current { valid.append(entry) }
            }
            return valid
        }

        public static func allocation(
            for entry: Entry,
            priority: Int = 0,
            required: Bool = false
        ) -> Allocation {
            Allocation(
                id: entry.record.id,
                pointer: entry.record.pointer,
                representation: .facts,
                priority: priority,
                required: required,
                dependencies: entry.record.derivedFrom
            )
        }

        private static func words(_ text: String) -> [String] {
            text.lowercased().split(whereSeparator: {
                !$0.isLetter && !$0.isNumber
            }).map(String.init)
        }
    }
}
