import Primitives
import Schema

/// A semantic value that accepts a loose `Raw` and stores only normalized
/// values, so no "resolved" accessor or second type is needed downstream.
///
/// What a caller may send is `Raw`, so the schema a model sees is `Raw`'s.
/// Decoding goes through `init(_:)`, so a decoded value is never weaker than
/// a constructed one.
public extension CodableInvariant where Raw: JSONSchemaProviding {
    static var jsonschema: JSONSchema {
        Raw.jsonschema
    }
}
