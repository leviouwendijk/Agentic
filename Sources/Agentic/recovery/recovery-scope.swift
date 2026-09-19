import Macros
import Primitives

public extension Recovery {
    struct Scope:
        Sendable,
        Codable,
        Hashable
    {
        public struct Kind: StringIdentifier {
            public let rawValue: String

            public init(
                rawValue: String
            ) {
                self.rawValue = rawValue
            }
        }

        public let kind: Kind
        public let identifier: String?

        public init(
            kind: Kind,
            identifier: String? = nil
        ) {
            self.kind = kind
            self.identifier = identifier
        }
    }
}

@StringIdentifiers
public extension Recovery.Scope.Kind {
    static var operation: Self
    static var inference: Self
    static var tool: Self
    static var task: Self
    static var run: Self
    static var subagent: Self
    static var adapter: Self
    static var workspace: Self
    static var harness: Self
}
