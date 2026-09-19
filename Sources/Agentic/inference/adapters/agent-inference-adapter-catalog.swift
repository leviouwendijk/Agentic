
public struct InferenceAdapterCatalog:
    InferenceAdapterResolving,
    Sendable
{
    private var adapters: [
        InferenceAdapterIdentifier:
            any InferenceAdapter
    ]

    public init() {
        self.adapters = [:]
    }

    public init(
        adapters: [any InferenceAdapter]
    ) throws {
        self.adapters = [:]

        for adapter in adapters {
            try register(
                adapter
            )
        }
    }

    public var count: Int {
        adapters.count
    }

    public var isEmpty: Bool {
        adapters.isEmpty
    }

    public var identifiers: [InferenceAdapterIdentifier] {
        adapters.keys.sorted { lhs, rhs in
            lhs.rawValue < rhs.rawValue
        }
    }

    public mutating func register(
        _ adapter: any InferenceAdapter
    ) throws {
        let identifier = adapter.identifier

        guard adapters[identifier] == nil else {
            throw InferenceAdapterCatalogError.duplicateAdapter(
                identifier.rawValue
            )
        }

        adapters[identifier] = adapter
    }

    public func adapter(
        for identifier: InferenceAdapterIdentifier
    ) -> (any InferenceAdapter)? {
        adapters[identifier]
    }

    public func require(
        _ identifier: InferenceAdapterIdentifier
    ) throws -> any InferenceAdapter {
        guard let adapter = adapters[identifier] else {
            throw InferenceAdapterCatalogError.unknownAdapter(
                identifier.rawValue
            )
        }

        return adapter
    }
}
