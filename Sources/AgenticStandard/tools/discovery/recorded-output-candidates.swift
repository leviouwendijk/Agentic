import Agentic
import Matching

/// A recorded output offers its segments' elements: the element's text as
/// the primary field, a record's fields as named secondary fields, so a
/// probe can be scoped to one (`severity`, `name`). Which call or segment an
/// element came from is its address, not a field: filters choose those.
extension RecordedOutput: CandidateSource {
    public struct Address: Sendable, Hashable {
        public let call: String
        public let segment: String
        /// The element's position in its segment, from 1.
        public let ordinal: Int
    }

    public struct Candidate: MatchCandidate {
        public let output: RecordedOutput
        public let segment: Segment
        public let element: Element

        public var matchID: Address {
            Address(call: output.call.id, segment: segment.name, ordinal: element.ordinal)
        }

        public var primaryField: MatchField {
            MatchField(name: "text", text: element.text, role: .primary)
        }

        public var secondaryFields: [MatchField] {
            element.fields.keys.sorted().map { name in
                MatchField(name: name, text: element.fields[name] ?? "", role: .secondary)
            }
        }

        public var metadata: MatchCandidateMetadata {
            .init()
        }
    }

    public func candidates() -> [Candidate] {
        segments.flatMap { segment in
            segment.elements.map { Candidate(output: self, segment: segment, element: $0) }
        }
    }
}
