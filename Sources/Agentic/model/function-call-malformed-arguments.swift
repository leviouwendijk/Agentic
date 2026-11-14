import Foundation
import Primitives

public extension FunctionCall {
    /// The `input` key holding arguments that were not valid JSON.
    static let malformedArgumentsKey = "$malformed_arguments"

    /// A call whose arguments a provider could not parse. It is kept, so the
    /// run answers it with an error the model can correct, rather than
    /// failing the whole model response.
    init(
        id: String,
        name: String,
        malformedArguments raw: String
    ) {
        self.init(
            id: id,
            name: name,
            input: .object([Self.malformedArgumentsKey: .string(raw)])
        )
    }

    /// The unparsed arguments, when the provider could not parse them.
    var malformedArguments: String? {
        guard case .object(let object) = input,
              object.count == 1,
              case .string(let raw)? = object[Self.malformedArgumentsKey]
        else {
            return nil
        }
        return raw
    }

    struct MalformedArguments: LocalizedError, Sendable {
        public let raw: String

        public init(raw: String) {
            self.raw = raw
        }

        public var errorDescription: String? {
            let excerpt = raw.count > 400 ? raw.prefix(400) + "…" : Substring(raw)
            return "The arguments of this call were not valid JSON, so it was not run: \(excerpt) "
                + "Emit the call again with one complete, valid JSON object as its arguments."
        }
    }
}
