import Primitives

/// A typed plan a Tool prepares during review and executes exactly in
/// `call(_:prepared:in:)`. The schema versions the plan's encoding.
public protocol AgentPreparedOperation: Sendable {
    associatedtype Plan:
        Sendable &
        Codable &
        Hashable

    static var schema: PreparedOperation.Schema { get }
}

public extension AgentPreparedOperation {
    static func envelope(
        _ plan: Plan
    ) throws -> PreparedOperation.Envelope {
        .init(
            schema: schema,
            plan: try JSONValue.encoding(
                plan
            )
        )
    }

    static func plan(
        from envelope: PreparedOperation.Envelope
    ) throws -> Plan {
        guard envelope.schema == schema else {
            throw PreparedOperation.EnvelopeError.schema_mismatch(
                expected: schema,
                actual: envelope.schema
            )
        }

        return try envelope.plan.decode(
            Plan.self
        )
    }
}
