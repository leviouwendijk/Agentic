import Macros
import Schema

@JSONSchema
public struct ToolReference:
    Sendable,
    Codable,
    Hashable
{
    public let identifier: ToolIdentifier
    public let owner: String?

    public init(
        identifier: ToolIdentifier,
        owner: String? = nil
    ) {
        self.identifier = identifier
        self.owner = owner
    }
}

public extension ToolReference {
    var name: String {
        identifier.rawValue
    }

    static func tool(
        _ identifier: ToolIdentifier,
        owner: String? = nil
    ) -> Self {
        .init(
            identifier: identifier,
            owner: owner
        )
    }

    static func tool(
        _ name: String,
        owner: String? = nil
    ) -> Self {
        .init(
            identifier: .init(name),
            owner: owner
        )
    }
}
