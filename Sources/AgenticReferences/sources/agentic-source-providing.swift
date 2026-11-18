import References

public protocol AgenticSourceProviding: ReferenceProviding {
    static var namespace: String { get }
}

public extension AgenticSourceProviding {
    var public_name_or_id: String {
        "\(Self.namespace).\(rawValue)"
    }
}
