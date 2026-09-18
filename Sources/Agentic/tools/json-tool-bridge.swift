// MOVE: AgenticExecution — JSONToolBridge belongs at the registration/type-erasure
// boundary where typed Tool Input/Output crosses into JSONValue.
// The old declaration is intentionally left commented until that move lands.
//
// import Foundation
// import Primitives
//
// public enum JSONToolBridge {
//     public static func decode<T: Decodable & Sendable>(
//         _ type: T.Type,
//         from value: JSONValue,
//         decoder _: JSONDecoder = JSONDecoder()
//     ) throws -> T {
//         try value.as(type)
//     }
//
//     public static func encode<T: Encodable & Sendable>(
//         _ value: T,
//         encoder: JSONEncoder = JSONEncoder()
//     ) throws -> JSONValue {
//         try JSONValueCodec.encodeValue(
//             value,
//             using: encoder
//         )
//     }
// }
