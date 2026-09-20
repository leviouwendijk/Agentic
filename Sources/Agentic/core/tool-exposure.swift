public protocol ToolAvailability: Sendable {
    var modelFacingDefinitions: [ToolDescriptor] { get }
}

public protocol ToolExposure: Sendable {
    func activate(
        _ identifiers: [ToolIdentifier]
    ) async throws -> [ToolIdentifier]
}
