public struct InferenceAdapterDefinition: Sendable, Codable, Hashable {
    public let identifier: InferenceAdapterIdentifier
    public init(identifier: InferenceAdapterIdentifier) {
        self.identifier = identifier
    }
}
