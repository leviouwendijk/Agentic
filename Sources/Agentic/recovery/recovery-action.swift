import Macros
import Primitives

public extension Recovery {
    struct Action: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}

@StringIdentifiers
public extension Recovery.Action {
    static var retry_same_operation: Self
    static var wait_then_retry: Self
    static var fallback_equivalent: Self
    static var repair_output: Self
    static var reconcile: Self
    static var suspend: Self
    static var invoke_authored_handler: Self
    static var propagate: Self
    static var abort: Self
}
