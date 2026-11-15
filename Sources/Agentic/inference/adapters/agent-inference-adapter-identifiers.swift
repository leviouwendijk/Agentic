
public extension InferenceAdapterIdentifier {
    static let native_structured = Self(
        rawValue: "native_structured"
    )

    /// Native structured output where the route supports it, prompted JSON
    /// otherwise. See `JSONAdapter`.
    static let json = Self(
        rawValue: "json"
    )
}
