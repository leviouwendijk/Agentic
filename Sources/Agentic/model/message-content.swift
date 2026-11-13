public struct MessageContent: Sendable, Codable, Hashable {
    public var blocks: [MessageContentBlock]

    public init(
        blocks: [MessageContentBlock] = []
    ) {
        self.blocks = blocks
    }
}

public extension MessageContent {
    init(
        text: String
    ) {
        self.init(blocks: [.text(text)])
    }

    init(
        resource: AgentResource
    ) {
        self.init(blocks: [.resource(resource)])
    }

    var text: String {
        blocks.compactMap { block in
            guard case .text(let value) = block else {
                return nil
            }

            return value
        }.joined()
    }

    var resources: [AgentResource] {
        blocks.compactMap { block in
            guard case .resource(let value) = block else {
                return nil
            }

            return value
        }
    }
}
