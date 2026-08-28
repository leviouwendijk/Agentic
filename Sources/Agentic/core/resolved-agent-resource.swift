import Foundation

public struct ResolvedAgentResource:
    Sendable
{
    public let resource: AgentResource
    public let data: Data

    public init(
        resource: AgentResource,
        data: Data
    ) {
        var resource = resource
        resource.byteCount = data.count

        self.resource = resource
        self.data = data
    }

    public var contentType: String? {
        resource.contentType
    }

    public var byteCount: Int {
        data.count
    }
}
