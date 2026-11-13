/// Immutable, execution-scoped dependencies supplied by a trusted host.
///
/// Values are keyed by their concrete Swift type. Reference values such as
/// actors retain their identity across copied service scopes.
/// Services are neither model-visible nor serialized into tool results.
public struct ToolServices: Sendable {
    public enum Failure: Error, Sendable, Equatable {
        case duplicate_type(String)
        case missing_type(String)
    }

    private var values: [ObjectIdentifier: any Sendable]

    public init() {
        values = [:]
    }

    public var isEmpty: Bool {
        values.isEmpty
    }

    /// Return a new scope containing one additional, uniquely typed service.
    public func inserting<Service: Sendable>(
        _ service: Service
    ) throws -> Self {
        let key = ObjectIdentifier(Service.self)
        guard values[key] == nil else {
            throw Failure.duplicate_type(String(reflecting: Service.self))
        }
        var copy = self
        copy.values[key] = service
        return copy
    }

    public func require<Service: Sendable>(
        _ type: Service.Type
    ) throws -> Service {
        guard let value = values[ObjectIdentifier(type)] as? Service else {
            throw Failure.missing_type(String(reflecting: type))
        }
        return value
    }
}
