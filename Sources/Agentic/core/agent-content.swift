public struct AgentContent: Sendable, Codable, Hashable {
    public var blocks: [AgentContentBlock]

    public init(
        blocks: [AgentContentBlock] = []
    ) {
        self.blocks = blocks
    }
}

public extension AgentContent {
    init(
        text: String
    ) {
        self.init(blocks: [.text(text)])
    }

    var text: String {
        blocks.compactMap { block in
            guard case .text(let value) = block else {
                return nil
            }

            return value
        }.joined()
    }
}
