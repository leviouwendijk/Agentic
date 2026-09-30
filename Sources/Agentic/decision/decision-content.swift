import Foundation
import Primitives
import Schema

public extension Decision {
    struct State: Sendable, Codable, Hashable {
        public let value: JSONValue

        public init<Value>(
            _ value: Value
        ) throws
        where Value: Encodable & Sendable
        {
            self.value = try Decision.jsonvalue(
                value
            )
        }
    }

    struct Content:
        Sendable,
        Codable,
        Hashable,
        JSONSchemaProviding,
        ExpressibleByStringLiteral
    {
        public enum Representation:
            Sendable,
            Codable,
            Hashable
        {
            case text(String)
            case null
            case structured(JSONValue)
        }

        public let representation: Representation

        public init(
            _ text: String
        ) {
            representation = .text(text)
        }

        public init(
            stringLiteral value: String
        ) {
            self.init(value)
        }

        public static var null: Self {
            .init(
                representation: .null
            )
        }

        public init<Value>(
            structured value: Value
        ) throws
        where Value: Encodable & Sendable
        {
            let data = try JSONEncoder().encode(
                value
            )
            let object = try JSONSerialization.jsonObject(
                with: data,
                options: [.fragmentsAllowed]
            )

            guard object is [String: Any]
                || object is [Any]
            else {
                throw Error.invalidStructuredContent
            }

            representation = .structured(
                try JSONDecoder().decode(
                    JSONValue.self,
                    from: data
                )
            )
        }

        public static var jsonschema: JSONSchema {
            .any
        }

        var isEmptyText: Bool {
            guard case .text(let value) = representation else {
                return false
            }

            return value
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
        }

        private init(
            representation: Representation
        ) {
            self.representation = representation
        }
    }
}

extension Decision {
    static func jsonvalue<Value: Encodable>(
        _ value: Value
    ) throws -> JSONValue {
        let data = try JSONEncoder().encode(
            value
        )

        return try JSONDecoder().decode(
            JSONValue.self,
            from: data
        )
    }
}
