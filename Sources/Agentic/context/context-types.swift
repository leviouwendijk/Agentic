import Foundation

/// Context is an addressable view over records; it does not own their storage.
public enum Context {}

public extension Context {
    struct Pointer: Sendable, Codable, Hashable {
        public enum Revision: Sendable, Codable, Hashable {
            case recorded(String)
            case latest
        }

        public enum Selection: Sendable, Codable, Hashable {
            case whole
            case lines(start: Int, end: Int)
            case key(String)
        }

        public let source: String
        public let record: String
        public let selection: Selection
        public let revision: Revision

        public init(
            source: String,
            record: String,
            selection: Selection = .whole,
            revision: Revision = .latest
        ) {
            self.source = source
            self.record = record
            self.selection = selection
            self.revision = revision
        }
    }

    /// Metadata about evidence, not a second copy of its content.
    struct Record: Sendable, Codable, Hashable {
        public let id: String
        public let kind: String
        public let pointer: Pointer
        public let derivedFrom: [Pointer]

        public init(
            id: String,
            kind: String,
            pointer: Pointer,
            derivedFrom: [Pointer] = []
        ) {
            self.id = id
            self.kind = kind
            self.pointer = pointer
            self.derivedFrom = derivedFrom
        }
    }

    /// Exact material observed by one resolver. Its pointer must name a
    /// recorded revision, even when the request asked for .latest.
    struct Resolved: Sendable, Codable, Hashable {
        public let pointer: Pointer
        public let messages: [Message]

        public init(pointer: Pointer, messages: [Message]) {
            self.pointer = pointer
            self.messages = messages
        }
    }

    /// Resolution is an authorization boundary owned by the source adapter.
    /// Possession of a pointer never itself grants read authority.
    protocol RecordResolving: Sendable {
        func resolve(_ pointer: Pointer) async throws -> Resolved
    }
}
