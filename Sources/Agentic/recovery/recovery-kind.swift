import Macros
import Primitives

public extension Recovery {
    struct Kind: StringIdentifier {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}

@StringIdentifiers
public extension Recovery.Kind {
    static var transport_transient: Self
    static var rate_limited: Self
    static var route_unavailable: Self
    static var structured_output_invalid: Self
    static var validation_failed: Self
    static var authorization_required: Self
    static var precondition_failed: Self
    static var conflict: Self
    static var outcome_unknown: Self
    static var cancelled: Self
    static var invariant_violation: Self
}
