import Foundation
import Primitives

/// A recorded response as named segments of addressed elements, for reading
/// and searching what a call returned rather than only what the model was
/// shown. Derived from the record (`output`), with the model's text as one
/// more segment when the capability rendered one.
///
/// - A multi-line string field (`stdout`, `log`) is a `lines` segment named
///   by its path, one element per line.
/// - An array of strings is a `lines` segment, one element per string (an
///   element may span lines).
/// - An array of objects is a `records` segment: each object's scalar fields
///   are the element's fields, and its text is those fields as `key: value`.
/// - `text`: the rendering the model read, when there was one.
/// - Nothing else derived and no rendering: `output`, the record as indented
///   JSON lines.
public struct RecordedOutput: Sendable, Hashable {
    public let call: FunctionCall.Reference
    public let isError: Bool
    public let segments: [Segment]

    public init(
        call: FunctionCall.Reference,
        isError: Bool,
        segments: [Segment]
    ) {
        self.call = call
        self.isError = isError
        self.segments = segments
    }

    public init(
        _ response: FunctionCall.Response
    ) {
        var segments = Self.segments(of: response.output, path: [])
        if let text = response.text {
            segments.append(.lines(Self.textSegment, text: text))
        } else if segments.isEmpty {
            if case .string(let string) = response.output {
                segments.append(.lines(Self.outputSegment, text: string))
            } else {
                segments.append(.lines(Self.outputSegment, text: Self.indented(response.output)))
            }
        }
        self.init(
            call: response.call,
            isError: response.isError,
            segments: segments
        )
    }

    /// The rendering the model read.
    public static let textSegment = "text"
    /// The record itself, when nothing more specific was derived.
    public static let outputSegment = "output"

    public func segment(
        named name: String
    ) -> Segment? {
        segments.first { $0.name == name }
    }
}

public extension RecordedOutput {
    struct Segment: Sendable, Hashable {
        public enum Kind: String, Sendable, Codable, Hashable {
            /// Text addressed by line.
            case lines
            /// Rows with fields.
            case records
        }

        public let name: String
        public let kind: Kind
        public let elements: [Element]

        public init(
            name: String,
            kind: Kind,
            elements: [Element]
        ) {
            self.name = name
            self.kind = kind
            self.elements = elements
        }

        /// One element per line, split as `ResultLines` splits them, so a
        /// segment's line numbers match what `standard_tool_read_result` pages.
        public static func lines(
            _ name: String,
            text: String
        ) -> Self {
            .init(
                name: name,
                kind: .lines,
                elements: ResultLines.lines(of: text).enumerated().map { index, line in
                    Element(ordinal: index + 1, text: String(line))
                }
            )
        }
    }

    /// One addressable part of a segment: a line, a multi-line block, or a
    /// record.
    struct Element: Sendable, Hashable {
        /// Position in its segment, from 1.
        public let ordinal: Int
        public let text: String
        /// A record's scalar fields; empty for lines.
        public let fields: [String: String]

        public init(
            ordinal: Int,
            text: String,
            fields: [String: String] = [:]
        ) {
            self.ordinal = ordinal
            self.text = text
            self.fields = fields
        }
    }
}

extension RecordedOutput {
    static func segments(
        of value: JSONValue,
        path: [String]
    ) -> [Segment] {
        let name = path.isEmpty ? outputSegment : path.joined(separator: ".")
        switch value {
        case .object(let object):
            return object.keys.sorted().flatMap { key in
                segments(of: object[key] ?? .null, path: path + [key])
            }
        case .string(let string) where string.contains("\n"):
            return [.lines(name, text: string)]
        case .array(let items) where !items.isEmpty:
            if items.allSatisfy({ if case .string = $0 { true } else { false } }) {
                return [.init(
                    name: name,
                    kind: .lines,
                    elements: items.enumerated().map { index, item in
                        guard case .string(let string) = item else { return Element(ordinal: index + 1, text: "") }
                        return Element(ordinal: index + 1, text: string)
                    }
                )]
            }
            if items.allSatisfy({ if case .object = $0 { true } else { false } }) {
                return [.init(
                    name: name,
                    kind: .records,
                    elements: items.enumerated().map { index, item in
                        record(item, ordinal: index + 1)
                    }
                )]
            }
            return []
        default:
            return []
        }
    }

    static func record(
        _ value: JSONValue,
        ordinal: Int
    ) -> Element {
        guard case .object(let object) = value else {
            return Element(ordinal: ordinal, text: "")
        }
        var fields: [String: String] = [:]
        for (key, field) in object {
            if let scalar = scalar(field) {
                fields[key] = scalar
            }
        }
        return Element(
            ordinal: ordinal,
            text: fields.keys.sorted().map { "\($0): \(fields[$0] ?? "")" }.joined(separator: "; "),
            fields: fields
        )
    }

    static func scalar(
        _ value: JSONValue
    ) -> String? {
        switch value {
        case .string(let string): string
        case .bool(let bool): String(bool)
        case .int(let int): String(int)
        case .double(let double): String(double)
        default: nil
        }
    }

    static func indented(
        _ value: JSONValue
    ) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return (try? encoder.encode(value)).map { String(decoding: $0, as: UTF8.self) } ?? ""
    }
}
